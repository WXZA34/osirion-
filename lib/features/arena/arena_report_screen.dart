import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:valerion/core/models/lat_lng.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'package:valerion/features/home/models/arc_data.dart';
import 'widgets/share_selection_dialog.dart';
import 'models/arena_models.dart';
import 'package:uuid/uuid.dart';
import 'package:valerion/core/providers/arc_provider.dart';

import 'widgets/performance_chart.dart';
import 'widgets/performance_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/polyline_utils.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';

class ArenaReportScreen extends ConsumerStatefulWidget {
  final String sportType;
  final double distanceKm;
  final int durationSeconds;
  final double averagePaceMinPerKm;
  final double syncPrecision;
  final List<LatLng> path;
  final List<double> speedProfile;

  const ArenaReportScreen({
    super.key,
    required this.sportType,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePaceMinPerKm,
    required this.syncPrecision,
    required this.path,
    required this.speedProfile,
  });

  @override
  ConsumerState<ArenaReportScreen> createState() => _ArenaReportScreenState();
}

class _ArenaReportScreenState extends ConsumerState<ArenaReportScreen> {
  bool _isSaving = true;
  bool _isCapturing = false;
  int _earnedForceXp = 0;
  int _earnedWisdomXp = 0;
  int _earnedAether = 0;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _calculateAndSaveXP();
  }

  Future<void> _calculateAndSaveXP() async {
    // 1. Calcul de base
    double forceBase = 0;
    double wisdomBase = 0;

    if (widget.sportType == 'RUNNING') {
      forceBase = widget.distanceKm * 100;
      if (widget.averagePaceMinPerKm > 0 && widget.averagePaceMinPerKm <= 4.5) {
        forceBase *= 1.50; // +50%
      } else if (widget.averagePaceMinPerKm > 0 &&
          widget.averagePaceMinPerKm <= 5.5) {
        forceBase *= 1.25; // +25%
      }
    } else if (widget.sportType == 'WALKING') {
      forceBase = widget.distanceKm * 20;
      wisdomBase = widget.distanceKm * 50;
    } else if (widget.sportType == 'CYCLING') {
      forceBase = widget.distanceKm * 20;
    }

    // 2. Bonus Winter Arc
    final currentArc = ArcData.getCurrentArc();
    if (currentArc.title.contains('WINTER')) {
      forceBase *= 1.2;
      wisdomBase *= 1.2;
    }

    // 2.5 Bonus de Synchronisation IA (Loop Precision) - Appliqué sur TOUT l'XP
    double syncMultiplier = 1.0;
    if (widget.syncPrecision > 95) {
      syncMultiplier = 1.5; // +50%
    } else if (widget.syncPrecision > 85) {
      syncMultiplier = 1.3; // +30%
    } else if (widget.syncPrecision > 70) {
      syncMultiplier = 1.1; // +10%
    }

    // Appliquer le bonus de synchro
    forceBase *= syncMultiplier;
    wisdomBase *= syncMultiplier;

    _earnedForceXp = forceBase.round();
    _earnedWisdomXp = wisdomBase.round();

    // 1 cristal d'Aether tous les 50 XP gagnés
    _earnedAether = (_earnedForceXp + _earnedWisdomXp) ~/ 50; 
    
    // Gain d'Aether minimum pour l'effort fourni
    if (_earnedAether == 0 && widget.distanceKm > 0.5) {
      _earnedAether = 1;
    }

    // 3. Sauvegarde Firebase
    try {
      final repository = ref.read(valerionRepositoryProvider);

      // Update User Stats
      final userOpt = await ref.read(userProfileProvider.future);
      if (userOpt != null) {
          await repository.addArenaResults(
            userOpt.id,
            widget.distanceKm,
            widget.durationSeconds,
          );
        }
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde: $e");
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      
      // Proposer la gravure pour chaque course terminée
      _offerEngraving();
    }
  }

  void _offerEngraving() {
    // Toutes les courses sont désormais éligibles à la gravure
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _showEngravingDialog();
      }
    });
  }

  void _showEngravingDialog() {
    final arc = ref.read(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: arc.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: arc.primaryColor, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: arc.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "DÉFI PERFORMANCE DÉTECTÉ",
                style: TextStyle(
                  color: isSummer ? arc.onSurfaceColor : Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 18,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performance exceptionnelle.",
              style: TextStyle(color: arc.primaryColor, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              "Voulez-vous graver ce tracé dans la section rivaux afin que d'autres puissent affronter votre Ghost ?",
              style: TextStyle(color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.7) : Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("IGNORER", style: TextStyle(color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.3) : Colors.white24)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _engraveRun();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: arc.primaryColor,
              foregroundColor: isSummer ? Colors.white : Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("GRAVER LE TRACÉ"),
          ),
        ],
      ),
    );
  }

  Future<void> _engraveRun() async {
    // Afficher un petit overlay de chargement/gravure
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("GRAVURE DANS LE COLISÉE EN COURS..."),
        backgroundColor: Colors.cyanAccent,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final userOpt = await ref.read(userProfileProvider.future);
      if (userOpt == null) return;

      final repository = ref.read(valerionRepositoryProvider);
      
      final run = ColosseumRunModel(
        id: const Uuid().v4(),
        title: "Parcours de ${userOpt.username} (${widget.distanceKm.toStringAsFixed(1)}km)",
        creatorId: userOpt.id,
        creatorPseudo: userOpt.username,
        activityType: widget.sportType,
        distance: widget.distanceKm,
        recordDuration: Duration(seconds: widget.durationSeconds),
        path: widget.path,
        speedProfile: widget.speedProfile,
      );

      await repository.addColosseumRun(run);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SESSION ENREGISTRÉE : TRACÉ PARTAGÉ AVEC LA COMMUNAUTÉ."),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERREUR DE GRAVURE : $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    if (pace <= 0 || pace.isInfinite || pace.isNaN || widget.distanceKm < 0.01) return "--:--";
    int m = pace.floor();
    int s = ((pace - m) * 60).round();
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _formatKmh(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm > 60) return "0.0";
    double kmh = 60.0 / paceMinPerKm;
    return kmh.toStringAsFixed(1);
  }

  void _showShareDialog() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    // 1. Générer l'URL de la carte statique pour éviter le freeze GPU sur émulateur
    String? staticMapUrl;
    if (widget.path.isNotEmpty) {
      try {
        if (widget.path.length < 2) {
          // Un seul point : on met un marqueur au lieu d'un trajet
          final point = widget.path.first;
          final marker = "pin-s-a+ff0000(${point.longitude},${point.latitude})";
          staticMapUrl = "https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/$marker/auto/600x400?padding=50&access_token=${AppConstants.mapboxAccessToken}";
        } else {
          final encodedPolyline = PolylineUtils.encode(widget.path);
          // On remplace les caractères spéciaux pour l'URL
          final safePolyline = Uri.encodeComponent(encodedPolyline);
          staticMapUrl = "https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/path-5+00ffff($safePolyline)/auto/600x400?padding=50&access_token=${AppConstants.mapboxAccessToken}";
        }
      } catch (e) {
        debugPrint("❌ [StaticMap] Erreur encodage : $e");
      }
    }

    // 2. Capture de la Performance Card
    try {
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        Material(
          type: MaterialType.transparency,
          child: MediaQuery(
            data: MediaQueryData.fromView(View.of(context)),
            child: PerformanceCard(
              sportType: widget.sportType,
              distanceKm: widget.distanceKm,
              duration: _formatTime(widget.durationSeconds),
              speed: _formatKmh(widget.averagePaceMinPerKm),
              pace: widget.averagePaceMinPerKm,
              path: widget.path,
              speedProfile: widget.speedProfile,
              primaryColor: ref.read(arcProvider).primaryColor,
              staticMapUrl: staticMapUrl,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 1000), 
      );

      if (!mounted) return;

      if (imageBytes != null) {
        final reportText = """
📊 BILAN DE PERFORMANCE OSIRION 📊
${widget.sportType} | ${widget.distanceKm.toStringAsFixed(2)} KM
⏱️ Temps : ${_formatTime(widget.durationSeconds)}
🚀 Vitesse : ${_formatKmh(widget.averagePaceMinPerKm)} km/h
🎯 Précision : ${widget.syncPrecision.toInt()}%
💪 XP : +${_earnedForceXp + _earnedWisdomXp}
""";

        showDialog(
          context: context,
          builder: (context) => ShareSelectionDialog(
            reportText: reportText,
            imageData: imageBytes,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ [Capture] Erreur : $e");
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;
    final primaryColor = arc.primaryColor;
    final surfaceColor = arc.surfaceColor;
    final onSurfaceColor = arc.onSurfaceColor;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: _isSaving
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text("SYNCHRONISATION DE LA SESSION...", 
                      style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold))
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: primaryColor,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "SESSION TERMINÉE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSummer ? onSurfaceColor : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1. MINI CARTE DU PARCOURS RÉALISÉ
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.path.isNotEmpty 
                            ? Builder(
                                builder: (context) {
                                  String url = "";
                                  if (widget.path.length < 2) {
                                    final p = widget.path.first;
                                    url = "https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/pin-s-a+ff0000(${p.longitude},${p.latitude})/auto/600x400?padding=50&access_token=${AppConstants.mapboxAccessToken}";
                                  } else {
                                    url = "https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/path-5+00ffff(${Uri.encodeComponent(PolylineUtils.encode(widget.path))})/auto/600x400?padding=50&access_token=${AppConstants.mapboxAccessToken}";
                                  }

                                  return CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: primaryColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Icon(Icons.map_outlined, color: primaryColor.withValues(alpha: 0.5), size: 40),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.black.withValues(alpha: 0.5),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined, color: primaryColor.withValues(alpha: 0.3), size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        "AUCUNE DONNÉE GPS",
                                        style: TextStyle(color: primaryColor.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                        // Pace Overlay
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "ALLURE MOY.",
                                  style: TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "${_formatPace(widget.averagePaceMinPerKm)} min/km",
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. ANALYSE DE LA VITESSE
                    Text(
                      "ANALYSE DE LA VITESSE (KM/H)",
                      style: TextStyle(
                        color: primaryColor.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PerformanceChart(
                      speedProfile: widget.speedProfile,
                      accentColor: primaryColor,
                    ),
                    const SizedBox(height: 32),

                    // Metrics Box
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isSummer ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow(
                            arc,
                            "DISTANCE",
                            "${widget.distanceKm.toStringAsFixed(2)} KM",
                            isSummer ? onSurfaceColor : Colors.white,
                          ),
                          Divider(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10, height: 32),
                          _buildMetricRow(
                            arc,
                            "TEMPS",
                            _formatTime(widget.durationSeconds),
                            isSummer ? onSurfaceColor.withValues(alpha: 0.6) : Colors.white70,
                          ),
                          Divider(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10, height: 32),
                          _buildMetricRow(
                            arc,
                            "VITESSE MOY.",
                            "${_formatKmh(widget.averagePaceMinPerKm)} KM/H",
                            primaryColor,
                          ),
                          Divider(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10, height: 32),
                          _buildMetricRow(
                            arc,
                            "PRECISION IA",
                            "${widget.syncPrecision.toInt()}%",
                            widget.syncPrecision > 80 ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // XP Box
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor),
                        boxShadow: [
                          if (!isSummer)
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                            ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "RÉCOMPENSES ACQUISES",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (_earnedForceXp > 0)
                                _buildRewardCircle("FORCE", "+$_earnedForceXp", Colors.redAccent),
                              if (_earnedWisdomXp > 0)
                                _buildRewardCircle("SAGESSE", "+$_earnedWisdomXp", Colors.blueAccent),
                              if (_earnedAether > 0)
                                _buildRewardCircle("AETHER", "+$_earnedAether", Colors.purpleAccent),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sharing Button
                    OutlinedButton.icon(
                      onPressed: _isCapturing ? null : _showShareDialog,
                      icon: _isCapturing 
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
                        : const Icon(Icons.share, size: 20),
                      label: Text(
                        _isCapturing ? "GÉNÉRATION EN COURS..." : "GÉNÉRER MA PERFORMANCE CARD",
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: () {
                        // Retourne proprement au navigateur principal Menu/Home
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "RETOURNER AU MENU",
                        style: TextStyle(
                          color: isSummer ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricRow(ArcData arc, String label, String value, Color valueColor) {
    final isSummer = arc.arcType == AlphaArc.summer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
