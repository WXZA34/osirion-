import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../shared/widgets/workout_overlay.dart';

class DojoCameraTestScreen extends StatefulWidget {
  const DojoCameraTestScreen({super.key});

  @override
  State<DojoCameraTestScreen> createState() => _DojoCameraTestScreenState();
}

class _DojoCameraTestScreenState extends State<DojoCameraTestScreen> {
  CameraController? _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Use the front camera for the Dojo
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: Camera Preview
          if (_isInit && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 16),
                  Text(
                    "Initialisation de la vision IA...",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),

          // Foreground: The Overlay (Workout UI)
          WorkoutOverlay(
            isDojoMode: true,
            onPause: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Entraînement en pause (Simulation)"),
                ),
              );
            },
          ),

          // Close button on top of everything
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
