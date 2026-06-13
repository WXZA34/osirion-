import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models/exercise_config.dart';
import 'counters/i_valerion_counter.dart';
import 'counters/elbow_engine.dart';
import 'counters/knee_engine.dart';
import 'counters/hip_hinge_engine.dart';
import 'counters/explosive_engine.dart';
import 'counters/mock_counter.dart';
import 'dojo_exercise_screen.dart';
import '../../core/providers/lab_settings_provider.dart';

class ExerciseDemoScreen extends ConsumerStatefulWidget {
  final ExerciseConfig config;

  const ExerciseDemoScreen({super.key, required this.config});

  @override
  ConsumerState<ExerciseDemoScreen> createState() => _ExerciseDemoScreenState();
}

class _ExerciseDemoScreenState extends ConsumerState<ExerciseDemoScreen>
    with TickerProviderStateMixin {
  // Lecteur vidéo (même système que GuidedWorkoutScreen)
  CachedVideoPlayerPlus? _cachedPlayer;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _videoError;
  bool _showSkipButton = false;
  Timer? _loadingTimeoutTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.config.videoUrl != null && widget.config.videoUrl!.isNotEmpty) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    String url = widget.config.videoUrl!;

    // Timeout de sécurité : bouton "Ignorer" après 5 sec (même logique que Guide)
    _loadingTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isVideoInitialized) {
        setState(() => _showSkipButton = true);
      }
    });

    try {
      // Résolution Firebase Storage si l'URL n'est pas déjà HTTP
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        try {
          url = await FirebaseStorage.instance.ref(url).getDownloadURL();
        } catch (e) {
          debugPrint("❌ [Storage] Erreur getDownloadURL pour $url : $e");
        }
      }

      if (url.startsWith('http://') || url.startsWith('https://')) {
        _cachedPlayer = CachedVideoPlayerPlus.networkUrl(Uri.parse(url));
      } else {
        _cachedPlayer = CachedVideoPlayerPlus.asset(url);
      }

      await _cachedPlayer!.initialize();
      _videoController = _cachedPlayer!.controller;
      _videoController!.setLooping(true);
      _videoController!.play();

      if (mounted) {
        _loadingTimeoutTimer?.cancel();
        setState(() {
          _isVideoInitialized = true;
          _videoError = null;
        });
      }
    } catch (e) {
      _loadingTimeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _videoError = "Impossible de charger la vidéo.";
          _showSkipButton = true;
        });
      }
      debugPrint("Erreur vidéo démo: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pulseController.dispose();
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  IValerionCounter _buildCounter() {
    final sensitivity = ref.read(labSettingsProvider).aiSensitivity;
    final id = widget.config.id;

    if (!widget.config.hasAiSupport) {
      return MockCounter(widget.config.name);
    }

    if (id.contains("pushups") || id.contains("pompes") || id.contains("tractions") ||
        id.contains("pull_ups") || id.contains("dips") || id.contains("sphinx")) {
      return ElbowEngine(exerciseId: id, sensitivity: sensitivity);
    } else if (id.contains("squat") || id.contains("fente")) {
      return KneeEngine(exerciseId: id, sensitivity: sensitivity);
    } else if (id.contains("relevs") || id.contains("v_ups") || id.contains("pike")) {
      return HipHingeEngine(exerciseId: id, sensitivity: sensitivity);
    } else if (id.contains("jumping") || id.contains("sauts")) {
      return ExplosiveEngine(exerciseId: id, sensitivity: sensitivity);
    } else {
      return MockCounter(widget.config.name);
    }
  }

  void _startExercise() {
    final counter = _buildCounter();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            DojoExerciseScreen(config: widget.config, counter: counter),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraLabel = widget.config.requiredCameraAngle == CameraAngle.profile
        ? 'PROFIL'
        : 'FACE';
    final cameraIcon = widget.config.requiredCameraAngle == CameraAngle.profile
        ? Icons.stay_current_landscape
        : Icons.stay_current_portrait;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: Stack(
        children: [
          // Fond dégradé
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1B2A), Color(0xFF0A0C10)],
                ),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // App Bar custom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          "DÉMONSTRATION",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Zone vidéo / Illustration
                _buildMediaSection(),

                // Infos exercice
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge type entraînement
                        Row(
                          children: [
                            _buildBadge(
                              widget.config.trainingType == 'FORCE'
                                  ? '⚡ FORCE'
                                  : '🔥 ENDURANCE',
                              widget.config.trainingType == 'FORCE'
                                  ? Colors.redAccent
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              '+${widget.config.defaultXpPerRep} XP / ${widget.config.unit == 'seconds' ? 'SEC' : 'REP'}',
                              Colors.orangeAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nom de l'exercice
                        Text(
                          widget.config.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          widget.config.description,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Carte angle caméra
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(cameraIcon, color: Colors.cyanAccent, size: 28),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "ANGLE CAMÉRA REQUIS",
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    "VUE DE $cameraLabel",
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bouton COMMENCER
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startExercise,
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text(
                          "COMMENCER LE PROTOCOLE",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 12,
                          shadowColor: Colors.greenAccent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      height: 230,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vidéo prête
            if (_videoController != null && _isVideoInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              // Illustration fallback
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Transform.scale(
                      scale: 1.0 + (_pulseAnimation.value - 0.9) * 0.5,
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.cyanAccent,
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "PRÉPARE-TOI",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Vidéo de démonstration\nbientôt disponible",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ],
              ),

            // Chargement en cours
            if (_videoController != null && !_isVideoInitialized && _videoError == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Colors.cyanAccent,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "CHARGEMENT DÉMO...",
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

            // Erreur vidéo
            if (_videoError != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white38, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      "Vidéo non disponible\nVous pourrez quand même démarrer l'exercice",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // Bouton Ignorer (après timeout)
            if (_showSkipButton && !_isVideoInitialized)
              Positioned(
                bottom: 12,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _videoError = "Vidéo ignorée.";
                    _showSkipButton = false;
                  }),
                  icon: const Icon(Icons.skip_next, color: Colors.white54, size: 16),
                  label: const Text(
                    "IGNORER LA DÉMO",
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
