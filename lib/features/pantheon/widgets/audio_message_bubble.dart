// lib/features/pantheon/widgets/audio_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final Color accentColor;
  final DateTime timestamp;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    required this.accentColor,
    required this.timestamp,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    // Pré-charger la durée si possible ou attendre le premier clic
  }

  void _initPlayer() {
    if (_audioPlayer != null) return;

    _audioPlayer = AudioPlayer();
    _audioPlayer!.setVolume(1.0);

    _playerStateSubscription =
        _audioPlayer!.onPlayerStateChanged.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state == PlayerState.playing;
            });
            if (state == PlayerState.completed) {
              _cleanUpPlayer();
            }
          }
        });

    _durationSubscription = _audioPlayer!.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSubscription = _audioPlayer!.onPositionChanged.listen((p) {
      if (mounted) {
        if ((p.inMilliseconds - _position.inMilliseconds).abs() > 200 ||
            p == _duration) {
          setState(() => _position = p);
        }
      }
    });
  }

  void _cleanUpPlayer() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isPlaying = false;
  }

  @override
  void dispose() {
    _cleanUpPlayer();
    super.dispose();
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer?.pause();
    } else {
      _initPlayer();
      
      Source source;
      // Déterminer si c'est un fichier local ou une URL distante
      if (widget.audioUrl.startsWith('/') || widget.audioUrl.contains('com.google.firebase')) {
        // Chemin local (Android/iOS) ou déjà uploadé Firebase (nécessite URL brute)
        if (widget.audioUrl.startsWith('http')) {
           final String encodedUrl = widget.audioUrl.replaceAll('!', '%21');
           source = UrlSource(encodedUrl);
        } else {
           source = DeviceFileSource(widget.audioUrl);
        }
      } else if (widget.audioUrl.startsWith('http')) {
        final String encodedUrl = widget.audioUrl.replaceAll('!', '%21');
        source = UrlSource(encodedUrl);
      } else {
        // Fallback pour les chemins locaux relatifs
        source = DeviceFileSource(widget.audioUrl);
      }
      
      await _audioPlayer!.play(source);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white.withValues(alpha: 0.8);
    final secondaryTextColor = Colors.white.withValues(alpha: 0.5);

    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Bouton Play Minimaliste
              GestureDetector(
                onTap: _playPause,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Barre de progression ultra-fine
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 2,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _duration.inMilliseconds > 0
                            ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Heure d'envoi intégrée
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatTime(widget.timestamp),
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 8,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
