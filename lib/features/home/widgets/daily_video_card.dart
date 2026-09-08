import 'package:valerion/features/home/utils/arc_translator.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/repository_providers.dart';
import '../models/arc_data.dart';
import '../../../../core/providers/arc_provider.dart';

class DailyVideoCard extends ConsumerStatefulWidget {
  const DailyVideoCard({super.key});

  @override
  ConsumerState<DailyVideoCard> createState() => _DailyVideoCardState();
}

class _DailyVideoCardState extends ConsumerState<DailyVideoCard> {
  // Youtube Player
  YoutubePlayerController? _youtubeController;
  
  // Firebase/Standard Player
  CachedVideoPlayerPlus? _cachedPlayer;
  VideoPlayerController? _videoController;
  
  bool _isYoutube = false;
  bool _isExternalLink = false;
  bool _isCustomVideoReady = false;
  bool _isMuted = false;
  String? _loadedUrl;
  
  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializePlayer(String url) {
    if (_loadedUrl == url) return; // Déjà chargé
    _loadedUrl = url;
    
    // Nettoyer les anciens contrôleurs si l'URL change
    _youtubeController?.dispose();
    _videoController?.dispose();
    _youtubeController = null;
    _videoController = null;
    _cachedPlayer = null;
    _isCustomVideoReady = false;
    _isExternalLink = false;

    // Détection Youtube vs Firebase/MP4
    final youtubeId = YoutubePlayer.convertUrlToId(url);
    if (youtubeId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: true,
          enableCaption: true,
        ),
      );
      setState(() {});
    } else if (url.contains('tiktok.com') || url.contains('instagram.com/reel/')) {
      _isYoutube = false;
      _isExternalLink = true;
      setState(() {});
    } else {
      _isYoutube = false;
      _cachedPlayer = CachedVideoPlayerPlus.networkUrl(Uri.parse(url));
      _cachedPlayer!.initialize().then((_) {
          if (mounted) {
            _videoController = _cachedPlayer!.controller;
            _videoController!.setVolume(1.0); // Forcer le volume à 100%
            setState(() {
              _isCustomVideoReady = true;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isExternalLink = true; // Fallback to external link on error
            });
          }
        });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isYoutube) {
        _isMuted ? _youtubeController?.mute() : _youtubeController?.unMute();
      } else {
        _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(globalConfigProvider);
    final ArcData currentArc = ref.watch(arcProvider);

    return configAsync.when(
      data: (config) {
        if (config == null) {
          if (kDebugMode) {
            debugPrint("⚠️ [DailyVideo] Le document 'daily_content' est INTROUVABLE dans Firestore !");
          }
          return _buildOfflinePlaceholder(context, currentArc, "SIGNAL PERDU", "La transmission Alpha est actuellement hors-ligne.");
        }

        if (config.dailyVideoUrl == null || config.dailyVideoUrl!.isEmpty) {
          if (kDebugMode) {
            debugPrint("⚠️ [DailyVideo] L'URL de la vidéo est vide dans Firestore !");
          }
          return _buildOfflinePlaceholder(context, currentArc, "SIGNAL FAIBLE", "En attente du prochain briefing tactique...");
        }

        final String videoUrl = config.dailyVideoUrl!;
        
        // Optimisation : Utiliser postFrameCallback pour ne pas bloquer le build initial
        if (_loadedUrl != videoUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (kDebugMode) {
                debugPrint("📡 [DailyVideo] Chargement de la transmission : $videoUrl");
              }
              _initializePlayer(videoUrl);
            }
          });
        }

        final bool isSummer = currentArc.arcType == AlphaArc.summer;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            color: isSummer ? Colors.white : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSummer ? Colors.black12 : Colors.white10),
            boxShadow: [
              BoxShadow(
                color: isSummer ? Colors.black.withValues(alpha: 0.05) : currentArc.primaryColor.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isSummer ? Colors.black12 : Colors.white10)),
                    gradient: LinearGradient(
                      colors: [
                        currentArc.primaryColor.withValues(alpha: isSummer ? 0.1 : 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_filled, color: currentArc.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.homeTransmissionAlpha,
                        style: TextStyle(
                          color: currentArc.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lecteur Vidéo
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildPlayerIndicator(currentArc),
                ),
                
                // Titre et description
                if (config.dailyVideoTitle != null || config.dailyVideoDescription != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (config.dailyVideoTitle != null)
                          Text(
                            config.dailyVideoTitle!.toUpperCase(),
                            style: TextStyle(
                              color: isSummer ? Colors.black87 : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        if (config.dailyVideoDescription != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            config.dailyVideoDescription!,
                            style: TextStyle(
                              color: isSummer ? Colors.black54 : Colors.white54,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading:
          () {
            final bool isSummer = currentArc.arcType == AlphaArc.summer;
            return Container(
              height: 200,
              margin: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                color: isSummer ? Colors.white : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isSummer ? Colors.black12 : Colors.transparent),
              ),
              child: Center(
                child: CircularProgressIndicator(color: isSummer ? currentArc.primaryColor : Colors.white24, strokeWidth: 2),
              ),
            );
          },
      error:
          (e, __) => _buildOfflinePlaceholder(context, currentArc, "ERREUR SYSTÈME",
            "Échec de synchronisation avec le satellite Alpha : $e",
          ),
    );
  }

  Widget _buildOfflinePlaceholder(BuildContext context, ArcData arc, String title, String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: arc.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off, color: arc.primaryColor.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            ArcTranslator.translate(context, title),
            style: TextStyle(
              color: arc.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ArcTranslator.translate(context, message),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: arc.arcType == AlphaArc.summer ? Colors.black38 : Colors.white38, 
              fontSize: 12
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(ArcData arc) {
    if (_isYoutube && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressColors: ProgressBarColors(
          playedColor: arc.primaryColor,
          handleColor: arc.secondaryColor,
        ),
      );
    } 
    
    if (_isExternalLink) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, color: arc.primaryColor, size: 48),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(AppLocalizations.of(context)!.homeOuvrirLaVidO, style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: arc.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (_loadedUrl != null) {
                    final uri = Uri.parse(_loadedUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (!_isYoutube && _videoController != null) {
      if (_isCustomVideoReady) {
        return Stack(
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
            // Bouton Play/Pause basique (le clic sur la vidéo gère la lecture)
            GestureDetector(
              onTap: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              child: Container(
                color: Colors.transparent, // Rend toute la zone cliquable
                constraints: const BoxConstraints.expand(),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            // Bouton Mute/Unmute
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Barre de progression
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: VideoProgressColors(
                  playedColor: arc.primaryColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      } else {
        return const Center(child: CircularProgressIndicator(color: Colors.white24));
      }
    }
    
    // Cas de secours
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.white24, size: 40),
      ),
    );
  }
}
