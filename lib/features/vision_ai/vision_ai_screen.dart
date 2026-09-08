import '../../l10n/app_localizations.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:valerion/core/utils/camera_utils.dart';

class VisionAIScreen extends StatefulWidget {
  const VisionAIScreen({super.key});

  @override
  State<VisionAIScreen> createState() => _VisionAIScreenState();
}

class _VisionAIScreenState extends State<VisionAIScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  // int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
  }

  Future<void> _initializePoseDetector() async {
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      // Handle permission denied
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use front camera by default if available for fitness apps
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller?.initialize();
    if (!mounted) return;

    _controller?.startImageStream(_processImage);
    setState(() {});
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isBusy || _poseDetector == null) return;
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isBusy = false;
      return;
    }

    try {
      final poses = await _poseDetector!.processImage(inputImage);
      // TODO: Add Painter logic here later
      if (kDebugMode) {
        debugPrint('Found ${poses.length} poses');
      }

      // For MVP, just print pose data or show simple overlay placeholder
      if (mounted) {
        setState(() {
          // Update overlay state here if needed
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }

    _isBusy = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // final camera = _controller!.description;
    // final sensorOrientation = camera.sensorOrientation;

    // Use the CameraUtils helper to convert
    // We need to pass the camera description and orientation
    // final camera = _controller!.description;
    return CameraUtils.inputImageFromCameraImage(image, _controller!, 1);
    // Note: 1 is a hardcoded index for now, ideal would be to track _cameraIndex properly
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),
          _customPaint ?? const SizedBox(),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.visionAiVisionAiActive,
                style: TextStyle(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
