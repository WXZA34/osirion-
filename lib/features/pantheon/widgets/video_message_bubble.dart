import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VideoMessageBubble extends StatefulWidget {
  final String videoUrl;
  final bool isMe;
  final Color accentColor;

  const VideoMessageBubble({
    super.key,
    required this.videoUrl,
    required this.isMe,
    required this.accentColor,
  });

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  CachedVideoPlayerPlus? _cachedPlayer;
  late VideoPlayerController _controller;
  bool _isInit = false;
  bool _isDownloading = false;

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
      if (mounted) setState(() => _isInit = true);
    }).catchError((e) {
      debugPrint("❌ Erreur VideoPlayer: $e");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    setState(() => _isDownloading = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      final response = await http.get(Uri.parse(widget.videoUrl));
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);

      await Gal.putVideo(savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vidéo enregistrée dans la pellicule ! ✅")),
        );
      }
    } catch (e) {
      debugPrint("❌ Erreur Download: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur téléchargement: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    return Column(
      crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                // On fixe un ratio max
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio.clamp(0.5, 2.0),
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            IconButton(
              iconSize: 50,
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: _isDownloading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download, size: 20, color: Colors.white54),
          onPressed: _downloadVideo,
          tooltip: "Enregistrer dans la pellicule",
        ),
      ],
    );
  }
}
