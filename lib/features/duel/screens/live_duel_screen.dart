import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pose_detector_service.dart';
import '../services/duel_sync_service.dart';
import '../analyzers/exercise_analyzer.dart';
import '../analyzers/pushup_analyzer.dart';
import '../analyzers/squat_analyzer.dart';
import '../analyzers/situp_analyzer.dart';
import '../widgets/pose_painter.dart';
import '../widgets/tug_of_war_bar.dart';

class LiveDuelScreen extends StatefulWidget {
  final String duelId;
  final String opponentId;
  final String exerciseType; // "pushups", "squats", "situps"

  const LiveDuelScreen({
    Key? key,
    required this.duelId,
    required this.opponentId,
    required this.exerciseType,
  }) : super(key: key);

  @override
  State<LiveDuelScreen> createState() => _LiveDuelScreenState();
}

class _LiveDuelScreenState extends State<LiveDuelScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final PoseDetectorService _poseService = PoseDetectorService();
  final DuelSyncService _syncService = DuelSyncService();
  late ExerciseAnalyzer _analyzer;
  
  bool _isBusy = false;
  List<Pose> _poses = [];
  CustomPaint? _customPaint;
  
  int _myReps = 0;
  int _opponentReps = 0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnalyzer();
    _initCamera();
    _initSync();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  void _initAnalyzer() {
    switch (widget.exerciseType) {
      case "squats":
        _analyzer = SquatAnalyzer();
        break;
      case "situps":
        _analyzer = SitupAnalyzer();
        break;
      case "pushups":
      default:
        _analyzer = PushupAnalyzer();
        break;
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      // For ML Kit on Android, nv21 is highly recommended to prevent performance issues / ANRs
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController?.initialize();
    if (!mounted) return;

    _cameraController?.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _initSync() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _syncService.initializeDuel(widget.duelId, userId, widget.opponentId);
    
    _syncService.opponentStream?.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _opponentReps = data['reps'] ?? 0;
        });
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      final imageRotation = InputImageRotation.rotation270deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
      
      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

      final poses = await _poseService.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        int repsToAdd = _analyzer.processPose(poses.first);
        if (repsToAdd > 0) {
          setState(() {
            _myReps += repsToAdd;
          });
          _syncService.sendRep(_myReps);
          _animationController.forward();
        }
      }

      if (mounted) {
        setState(() {
          _poses = poses;
          _customPaint = CustomPaint(
            painter: PosePainter(poses, imageSize, imageRotation),
          );
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseService.close();
    _syncService.leaveDuel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Background
          CameraPreview(_cameraController!),
          
          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.4)),

          // Skeleton Overlay
          if (_customPaint != null) _customPaint!,

          // Tug of War Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: TugOfWarBar(
              myReps: _myReps,
              opponentReps: _opponentReps,
              myColor: Colors.amber,
              opponentColor: Colors.deepOrangeAccent,
            ),
          ),

          // Rep Counter Center
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                '$_myReps',
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Opponent PiP
          Positioned(
            bottom: 30,
            right: 20,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.pinkAccent, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.pinkAccent, blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Adversaire', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(
                    '$_opponentReps',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 100,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
