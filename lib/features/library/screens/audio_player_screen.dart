import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../home/models/arc_data.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String audioPath;
  final bool isAsset;

  const AudioPlayerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.audioPath,
    this.isAsset = true,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  bool get _isSummer => _currentArc.arcType == AlphaArc.summer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;

  ArcData get _currentArc => ArcData.getCurrentArc();
  Color get _accentColor => _currentArc.primaryColor;
  Color get _surfaceColor => _currentArc.surfaceColor;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSliding = false;
  DateTime _lastUpdateTime = DateTime.now();

  late StreamSubscription<PlayerState> _playerStateSubscription;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final bool effectivelyAsset = widget.isAsset && !widget.audioPath.startsWith('http');
      await _audioPlayer.setVolume(1.0);

      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
        state,
      ) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _durationSubscription = _audioPlayer.onDurationChanged.listen((
        newDuration,
      ) {
        if (mounted) {
          setState(() {
            _duration = newDuration;
          });
        }
      });

      _positionSubscription = _audioPlayer.onPositionChanged.listen((
        newPosition,
      ) {
        if (mounted && !_isSliding) {
          final now = DateTime.now();
          if (now.difference(_lastUpdateTime).inMilliseconds > 300) {
            setState(() {
              _position = newPosition;
              _lastUpdateTime = now;
            });
          } else {
            _position = newPosition;
          }
        }
      });

      // Auto-play when ready
      if (effectivelyAsset) {
        await _audioPlayer.play(AssetSource(widget.audioPath));
      } else {
        // Android MediaPlayer is very sensitive to special characters like '!'
        // Firebase Storage URLs often have '!' which must be encoded as %21
        final String encodedUrl = widget.audioPath.replaceAll('!', '%21');
        await _audioPlayer.play(UrlSource(encodedUrl));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading audio: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur de lecture : $e",
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Deep space blue/black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: _isSummer ? _currentArc.onSurfaceColor : Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cover Art / Animation area
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_surfaceColor.withValues(alpha: 0.8), _surfaceColor],
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(
                        alpha: _isPlaying ? 0.3 : 0.1,
                      ),
                      blurRadius: _isPlaying ? 50 : 20,
                      spreadRadius: _isPlaying ? 10 : 0,
                    ),
                  ],
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.headphones,
                    size: 80,
                    color: _accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Title and Subtitle
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isSummer ? _currentArc.onSurfaceColor : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Progress Bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accentColor,
                  inactiveTrackColor: _isSummer ? Colors.black12 : Colors.white24,
                  thumbColor: _isSummer ? _accentColor : Colors.white,
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16.0,
                  ),
                ),
                child: Slider(
                  min: 0.0,
                  max:
                      _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 100.0,
                  value: _position.inMilliseconds.toDouble().clamp(
                    0.0,
                    _duration.inMilliseconds.toDouble() > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 100.0,
                  ),
                  onChangeStart: (value) {
                    setState(() {
                      _isSliding = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _position = Duration(milliseconds: value.toInt());
                    });
                  },
                  onChangeEnd: (value) {
                    final position = Duration(milliseconds: value.toInt());
                    _audioPlayer.seek(position);
                    setState(() {
                      _isSliding = false;
                    });
                  },
                ),
              ),

              // Time Indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: _isSummer ? _currentArc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.replay_10,
                      color: _isSummer ? _currentArc.onSurfaceColor : Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      final newPosition =
                          _position - const Duration(seconds: 10);
                      _audioPlayer.seek(
                        newPosition < Duration.zero
                            ? Duration.zero
                            : newPosition,
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF020617),
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: const Color(0xFF020617),
                                size: 48,
                              ),
                      padding: const EdgeInsets.all(16),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                if (_isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.resume();
                                }
                              },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.forward_10,
                      color: _isSummer ? _currentArc.onSurfaceColor : Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      final newPosition =
                          _position + const Duration(seconds: 10);
                      _audioPlayer.seek(
                        newPosition > _duration ? _duration : newPosition,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
