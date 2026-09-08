import 'package:valerion/features/dojo/utils/dojo_translator.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'models/exercise_config.dart';
import 'dojo_report_screen.dart';

enum GuidedState { demonstration, preparation, action }

class GuidedWorkoutScreen extends StatefulWidget {
  final ExerciseConfig config;

  const GuidedWorkoutScreen({super.key, required this.config});

  @override
  State<GuidedWorkoutScreen> createState() => _GuidedWorkoutScreenState();
}

class _GuidedWorkoutScreenState extends State<GuidedWorkoutScreen> {
  GuidedState _currentState = GuidedState.demonstration;

  // States variables
  int _preparationSeconds = 3;
  int _workoutSeconds = 0;
  int _completedReps = 0;
  Timer? _timer;

  // Video variables
  CachedVideoPlayerPlus? _cachedPlayer;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _videoError;
  bool _showSkipButton = false;
  Timer? _loadingTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.config.videoUrl != null) {
      String url = widget.config.videoUrl!;

      // Démarrer un timer de sécurité pour afficher le bouton "Passer" après 5 sec
      _loadingTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_isVideoInitialized) {
          setState(() => _showSkipButton = true);
        }
      });

      try {
        // Résolution de l'URL Firebase Storage si nécessaire
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          try {
            url = await FirebaseStorage.instance.ref(url).getDownloadURL();
          } catch (e) {
            debugPrint("❌ [Storage] Erreur getDownloadURL pour $url : $e");
            // On laisse l'erreur remonter ou on tente l'asset par défaut (auto-healing)
          }
        }

        if (url.startsWith('http://') || url.startsWith('https://')) {
          _cachedPlayer = CachedVideoPlayerPlus.networkUrl(
            Uri.parse(url),
          );
        } else {
          _cachedPlayer = CachedVideoPlayerPlus.asset(
            url,
          );
        }

        await _cachedPlayer!.initialize();
        _videoController = _cachedPlayer!.controller;
        await _videoController!.setVolume(1.0); // Garantie que le son est activé

        if (mounted) {
          _loadingTimeoutTimer?.cancel();
          setState(() {
            _isVideoInitialized = true;
            _videoError = null;
          });
          _videoController!.setLooping(true);
          _videoController!.play();
        }
      } catch (e) {
        _loadingTimeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _videoError = DojoTranslator.translate(context, "Erreur de chargement de la vidéo : $e");
            _showSkipButton = true;
          });
        }
        debugPrint("Erreur lecteur vidéo : $e");
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loadingTimeoutTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _startPreparation() {
    setState(() {
      _currentState = GuidedState.preparation;
      _preparationSeconds = 3;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_preparationSeconds > 1) {
        setState(() => _preparationSeconds--);
      } else {
        _timer?.cancel();
        _startAction();
      }
    });
  }

  void _startAction() {
    setState(() {
      _currentState = GuidedState.action;
      _workoutSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _workoutSeconds++);
    });
  }

  void _finishWorkout() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => DojoReportScreen(
              config: widget.config,
              completedReps: _completedReps,
            ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          DojoTranslator.translate(context, widget.config.name).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // UPPER PORTION : The Media (Video Player or Placeholder)
            _buildMediaSection(),

            const SizedBox(height: 24),

            // LOWER PORTION : The Interaction
            Expanded(child: _buildInteractionSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
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
              // Placeholder when no video
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white24,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.dojoSimulationHq,
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      DojoTranslator.translateDescription(context, widget.config.description),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),

            // Video Loading Progress
            if (_videoController != null &&
                !_isVideoInitialized &&
                _videoError == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.dojoCalibrageDuFlux,
                    style: TextStyle(
                      color: Colors.blueAccent.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

            // Error Message
            if (_videoError != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.orangeAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _videoError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            // Skip Button Overlay
            if (_showSkipButton && !_isVideoInitialized)
              Positioned(
                bottom: 16,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _videoError = DojoTranslator.translate(context, "Vidéo ignorée par l'utilisateur.");
                      _isVideoInitialized = false;
                    });
                  },
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white54,
                    size: 16,
                  ),
                  label: Text(AppLocalizations.of(context)!.dojoIgnorerLaDMo,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),

            // Preparation Overlay
            if (_currentState == GuidedState.preparation)
              Container(
                decoration: const BoxDecoration(color: Colors.black87),
                child: Center(
                  child: Text(
                    "$_preparationSeconds",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionSection() {
    switch (_currentState) {
      case GuidedState.demonstration:
        return Center(
          child: ElevatedButton.icon(
            onPressed: _startPreparation,
            icon: const Icon(Icons.bolt, color: Colors.blueAccent, size: 28),
            label: Text(AppLocalizations.of(context)!.dojoDMarrerLEntra,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );

      case GuidedState.preparation:
        return Center(child: Text(AppLocalizations.of(context)!.dojoPrParezVous,
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        );

      case GuidedState.action:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Chrono
            Text(
              _formatTime(_workoutSeconds),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),

            // Tap Area
            GestureDetector(
              onTap: () {
                setState(() => _completedReps++);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_completedReps",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    Text(AppLocalizations.of(context)!.dojoRPTitions,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(AppLocalizations.of(context)!.dojoTapezLeCercleChaque,
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),

            // Finish Button
            ElevatedButton(
              onPressed: _finishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "TERMINER",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        );
    }
  }
}
