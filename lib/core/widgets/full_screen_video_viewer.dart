import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'dart:io';

class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoViewer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  CachedVideoPlayerPlus? _cachedPlayer;
  late VideoPlayerController _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.startsWith('/') || !widget.videoUrl.startsWith('http')) {
      _cachedPlayer = CachedVideoPlayerPlus.file(File(widget.videoUrl));
    } else {
      _cachedPlayer = CachedVideoPlayerPlus.networkUrl(Uri.parse(widget.videoUrl));
    }

    _cachedPlayer!.initialize().then((_) {
      _controller = _cachedPlayer!.controller;
      _controller.play();
      if (mounted) setState(() => _isInit = true);
    }).catchError((e) {
      debugPrint("❌ Erreur FullScreen VideoPlayer: $e");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isInit
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          },
                          child: AnimatedOpacity(
                            opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.redAccent),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
