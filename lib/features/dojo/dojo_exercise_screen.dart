import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'models/exercise_config.dart';
import 'counters/i_valerion_counter.dart';
import 'counters/mock_counter.dart';
import 'widgets/pose_painter.dart';
import 'widgets/recap_dialog.dart';
import 'services/pose_smoother.dart';
import '../home/providers/daily_pulse_provider.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/lab_settings_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/services/tts_service.dart';

class DojoExerciseScreen extends ConsumerStatefulWidget {
  final ExerciseConfig config;
  final IValerionCounter counter;

  const DojoExerciseScreen({
    super.key,
    required this.config,
    required this.counter,
  });

  @override
  ConsumerState<DojoExerciseScreen> createState() => _DojoExerciseScreenState();
}

class _DojoExerciseScreenState extends ConsumerState<DojoExerciseScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _cameraIndex = -1;
  List<CameraDescription> _cameras = [];
  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _questAutoValidated = false;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  DateTime _lastFrameTime = DateTime.now(); // Pour le throttling
  final DateTime _sessionStartTime = DateTime.now(); // Chrono séance
  late ConfettiController _confettiController;

  // Lissage exponentiel des landmarks pour éliminer le jitter visuel
  final PoseSmoother _smoother = PoseSmoother();

  // Optimisation rendu : ValueNotifier pour éviter le setState global à chaque frame
  final ValueNotifier<List<Pose>> _posesNotifier = ValueNotifier([]);
  final ValueNotifier<Size?> _imageSizeNotifier = ValueNotifier(null);
  final ValueNotifier<InputImageRotation?> _rotationNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _initCamera();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Initialisation TTS pour éviter les délais lors de la première rep
    TtsService().init();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Front camera is mandatory for self-training
    _cameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex == -1) _cameraIndex = 0;

    _cameraController = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium, // Passé en 480p pour une fluidité "insolente" (Zéro Lag)
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isDisposed) return;

    // Throttling adaptatif : On limite à 25 FPS max pour préserver CPU/Batterie
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < 40) {
      return; 
    }
    _lastFrameTime = now;

    _isProcessing = true;

    try {
      // Conversion YUV → NV21 robuste (fonctionne sur émulateurs et vrais appareils)
      final Uint8List bytes = Platform.isAndroid
          ? _convertYUV420ToNV21(image)
          : _concatPlanes(image);

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final camera = _cameras[_cameraIndex];
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

      final poses = await _poseDetector.processImage(inputImage);

      bool newRepCompleted = false;
      if (poses.isNotEmpty) {
        newRepCompleted = widget.counter.processPose(poses.first);
      }

      if (mounted) {
        // Lissage anti-jitter avant envoi au renderer
        final smoothedPoses = _smoother.smooth(poses);
        _posesNotifier.value = smoothedPoses;
        _imageSizeNotifier.value = imageSize;
        _rotationNotifier.value = imageRotation;

        if (newRepCompleted) {
          debugPrint("Répétition validée : ${widget.counter.count}");
          setState(() {}); // On ne trigger setState QUE lors d'une nouvelle rép ou changement d'état

          // ANTI-TRICHE : Validation automatique de la Quête Pushups
          if (widget.counter.name == "POMPES" &&
              widget.counter.count >= 50 &&
              !_questAutoValidated) {
            
            if (!mounted) return; // Sécurité anti-crash
            
            _questAutoValidated = true;
            ref
                .read(dailyPulseProvider.notifier)
                .autoValidateQuest("Valider 50 pompes");

            _confettiController.play();

            // Petit feedback visuel - Sécurisé avec mounted
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "🏆 QUÊTE QUOTIDIENNE ACCOMPLIE : 50 POMPES ! (+20 XP)",
                ),
                backgroundColor: Colors.cyan,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur IA: $e");
    } finally {
      // TOUJOURS libérer le flag, même si le widget a été fermé
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isProcessing = false;

    // FIX #1 : Couper immédiatement la voix TTS pour éviter le "comptage fantôme"
    TtsService().stop();

    // Arrêt sécurisé du stream caméra AVANT dispose
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}

    // Légère pause pour laisser les callbacks en cours se terminer proprement
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        _cameraController?.dispose();
      } catch (_) {}
    });

    _poseDetector.close();
    _confettiController.dispose();
    _posesNotifier.dispose();
    _imageSizeNotifier.dispose();
    _rotationNotifier.dispose();
    super.dispose();
  }

  Future<void> _saveSessionResults() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    final repo = ref.read(valerionRepositoryProvider);
    final arc = ArcData.getCurrentArc();
    final now = DateTime.now();
    // Format requis par le serveur : yyyy-MM-dd
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final reps = widget.counter.count;
    // On ne sauvegarde que si l'utilisateur a fait au moins un mouvement
    if (reps <= 0) return;

    final xp = reps * widget.config.defaultXpPerRep;

    try {
      debugPrint("💾 [Dojo] Enregistrement session : $reps reps (~$xp XP) ID Arc: ${arc.arcType.name}");
      
      // On lance la sauvegarde. Le serveur gère XP, Aether, Records et Calendrier.
      await repo.addWorkoutResults(
        user.id,
        reps,
        xp,
        0, // L'Aether est calculé côté serveur pour sécurité
        localDateStr: dateStr,
        arcId: arc.arcType.name,
      );
    } catch (e) {
      debugPrint("❌ [Dojo] Échec sauvegarde session : $e");
    }
  }

  void _showRecap() {
    final duration = DateTime.now().difference(_sessionStartTime);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RecapDialog(
        config: widget.config,
        repCount: widget.counter.count,
        sessionDuration: duration,
        onQuit: () {
          _saveSessionResults(); // Sauvegarde asynchrone au moment de quitter
          Navigator.of(context).pop(); // Ferme le bottom sheet
          Navigator.of(context).pop(); // Ferme DojoExerciseScreen
        },
        onReplay: () {
          _saveSessionResults(); // Sauvegarde asynchrone au moment de relancer
          Navigator.of(context).pop(); // Ferme le bottom sheet
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DojoExerciseScreen(
                config: widget.config,
                counter: widget.counter,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainScaffold = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Flux Vidéo
          if (_isCameraInitialized && _cameraController != null) ...[
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize!.height,
                    height: _cameraController!.value.previewSize!.width,
                    child: Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        Positioned.fill(
                          child: ValueListenableBuilder<List<Pose>>(
                            valueListenable: _posesNotifier,
                            builder: (context, poses, _) {
                              if (poses.isEmpty ||
                                  _imageSizeNotifier.value == null ||
                                  _rotationNotifier.value == null) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                painter: PosePainter(
                                  poses,
                                  _imageSizeNotifier.value!,
                                  _rotationNotifier.value!,
                                  _cameras[_cameraIndex].lensDirection,
                                  showSkeleton:
                                      ref.watch(labSettingsProvider).showSkeleton,
                                  faultyLandmarks: widget.counter.faultyLandmarks,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 16),
                  Text(
                    "Connexion Neurologique...",
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

          // 2. Bouton Retour
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // 3. Bouton TERMINER (en haut à droite)
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _showRecap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "TERMINER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- AJOUT : Overlay de Calibration ---
          if (widget.counter.isCalibrating)
            Positioned(
              top: 140,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "CALIBRATION IA EN COURS...",
                      style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "ADAPTATION À VOTRE MORPHOLOGIE",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.config.requiredCameraAngle == CameraAngle.profile 
                      ? Icons.stay_current_landscape 
                      : Icons.stay_current_portrait,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "ANGLE OBLIGATOIRE : ${widget.config.requiredCameraAngle == CameraAngle.face ? 'FACE' : 'PROFIL'}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. HUD Compteur de pompes
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  widget.counter.name,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (widget.counter is MockCounter) {
                      setState(() {
                        (widget.counter as MockCounter).incrementManual();

                        // ANTI-TRICHE : Validation automatique pour mock (facultatif)
                        if (widget.counter.count >= 50 &&
                            !_questAutoValidated) {
                          _questAutoValidated = true;
                          ref
                              .read(dailyPulseProvider.notifier)
                              .autoValidateQuest("Valider 50 pompes");
                        }
                      });
                    }
                  },
                  child: Text(
                    widget.counter.count.toString(),
                    style: TextStyle(
                      color:
                          _posesNotifier.value.isEmpty && widget.counter is! MockCounter
                              ? Colors.white24
                              : Colors.cyanAccent,
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows:
                          _posesNotifier.value.isNotEmpty || widget.counter is MockCounter
                              ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 20,
                                ),
                              ]
                              : null,
                    ),
                  ),
                ),
                if (_posesNotifier.value.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Text(
                      "CORPS NON DÉTECTÉ",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        mainScaffold,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 30, // Explosion plus forte
            minBlastForce: 15,
            emissionFrequency: 0.1,
            numberOfParticles: 50,
            gravity: 0.1, // Tombe plus lentement (rêve)
            colors: const [
              Colors.cyan,
              Colors.greenAccent,
              Colors.white,
              Colors.amber,
            ],
          ),
        ),
      ],
    );
  }

  /// Conversion YUV_420_888 (3 plans séparés) → NV21 (Y + VU entrelacé).
  /// C'est le format attendu par ML Kit sur Android.
  /// Compatible aussi bien avec les vrais appareils qu'avec les émulateurs.
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;

    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // Plan Y : copie directe ligne par ligne (en tenant compte du stride)
    final Plane yPlane = image.planes[0];
    int yIndex = 0;
    for (int row = 0; row < height; row++) {
      nv21.setRange(
        yIndex,
        yIndex + width,
        yPlane.bytes,
        row * yPlane.bytesPerRow,
      );
      yIndex += width;
    }

    // Plans U et V → entrelacement VU (NV21 = V avant U)
    // Sur émulateur YUV_420_888, il y a 3 plans séparés.
    // Sur vrai appareil NV21, il peut n'y avoir que 2 plans.
    if (image.planes.length == 3) {
      final Plane uPlane = image.planes[1];
      final Plane vPlane = image.planes[2];
      int uvIndex = ySize;
      final int uvRowStride = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int uvOffset = row * uvRowStride + col * uvPixelStride;
          if (uvIndex + 1 < nv21.length) {
            nv21[uvIndex++] = vPlane.bytes[uvOffset]; // V d'abord (NV21)
            nv21[uvIndex++] = uPlane.bytes[uvOffset]; // puis U
          }
        }
      }
    } else {
      // Plan UV déjà entrelacé (vrai appareil NV21)
      nv21.setRange(ySize, nv21.length, image.planes[1].bytes);
    }

    return nv21;
  }

  /// Concaténation simple des plans pour iOS (BGRA8888 n'a qu'un seul plan).
  Uint8List _concatPlanes(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}
