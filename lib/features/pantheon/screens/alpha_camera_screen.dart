import '../../../l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AlphaCameraScreen extends StatefulWidget {
  const AlphaCameraScreen({super.key});

  @override
  State<AlphaCameraScreen> createState() => _AlphaCameraScreenState();
}

class _AlphaCameraScreenState extends State<AlphaCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isRecording = false;
  int _secondsRemaining = 15;
  Timer? _timer;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    await _initController();
  }

  Future<void> _initController() async {
    _isCameraInitialized = false;
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.veryHigh, // 1080p pour une netteté maximale
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _toggleCamera() async {
    if (_isRecording) return;
    setState(() {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    });
    await _initController();
  }

  void _startRecording() async {
    if (_controller == null || !_isCameraInitialized || _isRecording) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _secondsRemaining = 15;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _stopRecording();
          }
        });
      });
    } catch (e) {
      debugPrint("Recording Error: $e");
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    try {
      final file = await _controller!.stopVideoRecording();
      if (mounted) {
        Navigator.pop(context, file); // Renvoie le XFile au PantheonScreen
      }
    } catch (e) {
      debugPrint("Stop Error: $e");
      if (mounted) setState(() => _isRecording = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    // Calcul du ratio pour le plein écran anti-étirement
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Preview plein écran
          ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. HUD - Barre de Progression (Haut)
          if (_isRecording)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (15 - _secondsRemaining) / 15,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  minHeight: 6,
                ),
              ),
            ),

          // 3. Bouton Retour
          Positioned(
            top: 45,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 4. Contrôles Bas
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bascule Caméra
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 30),
                  onPressed: _isRecording ? null : _toggleCamera,
                ),

                // Bouton Capture
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.redAccent : Colors.white,
                      ),
                      child: Center(
                        child: _isRecording 
                          ? Text("$_secondsRemaining", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                      ),
                    ),
                  ),
                ),

                // Placeholder pour alignement
                const SizedBox(width: 50),
              ],
            ),
          ),

          // 5. Filigrane Alpha
          Positioned(
            top: 45,
            right: 20,
            child: Text(
              AppLocalizations.of(context)!.pantheonAlphaCam,
              style: TextStyle(
                color: Colors.white38,
                letterSpacing: 3,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
