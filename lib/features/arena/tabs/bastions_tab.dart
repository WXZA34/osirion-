import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/core/models/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import '../models/arena_models.dart';
import '../services/poi_service.dart';
import '../../../core/providers/arc_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../home/models/arc_data.dart';

class BastionsTab extends ConsumerStatefulWidget {
  const BastionsTab({super.key});

  @override
  ConsumerState<BastionsTab> createState() => _BastionsTabState();
}

class _BastionsTabState extends ConsumerState<BastionsTab> {
  bool _isLoading = false;
  List<BastionModel> _spots = [];
  LatLng? _userPos;

  @override
  void initState() {
    super.initState();
    _scanForSpots();
  }

  Future<void> _scanForSpots() async {
    setState(() => _isLoading = true);

    try {
      Position pos = await Geolocator.getCurrentPosition();

      // SÉCURITÉ : Anti-Triche (Mock Locations / Fake GPS)
      if (pos.isMocked) {
        throw Exception("POS_MOCKED");
      }

      LatLng userLatLng = LatLng(pos.latitude, pos.longitude);

      final spots = await PoiService.findWorkoutSpots(userLatLng, 5000);

      // Tri par distance
      spots.sort((a, b) {
        double distA = Geolocator.distanceBetween(
          userLatLng.latitude,
          userLatLng.longitude,
          a.position.latitude,
          a.position.longitude,
        );
        double distB = Geolocator.distanceBetween(
          userLatLng.latitude,
          userLatLng.longitude,
          b.position.latitude,
          b.position.longitude,
        );
        return distA.compareTo(distB);
      });

      if (mounted) {
        setState(() {
          _userPos = userLatLng;
          _spots = spots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains("POS_MOCKED")) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                AppLocalizations.of(context)!.arenaTricheDTectE,
              ),
            ),
          );
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDistance(LatLng spotPos) {
    if (_userPos == null) return "--";
    double meters = Geolocator.distanceBetween(
      _userPos!.latitude,
      _userPos!.longitude,
      spotPos.latitude,
      spotPos.longitude,
    );
    if (meters < 1000) return "${meters.toInt()}m";
    return "${(meters / 1000).toStringAsFixed(1)}km";
  }

  Future<void> _claimSpot(BastionModel spot) async {
    final TextEditingController dipsController = TextEditingController(text: "0");
    final TextEditingController pullupsController = TextEditingController(
      text: "0",
    );
    final TextEditingController pushupsController = TextEditingController(
      text: "0",
    );
    final TextEditingController absController = TextEditingController(text: "0");

    final arc = ref.read(arcProvider);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: arc.surfaceColor,
                title: Text(
                  AppLocalizations.of(context)!.arenaDefiPrefix + spot.name,
                  style: TextStyle(
                    color: arc.primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.arenaDClarezVosR,
                        style: TextStyle(
                          color: arc.onSurfaceColor.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildExerciseInput(
                              AppLocalizations.of(context)!.arenaTractions,
                              pullupsController,
                              arc,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildExerciseInput(
                              AppLocalizations.of(context)!.arenaDips,
                              dipsController,
                              arc,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildExerciseInput(
                              AppLocalizations.of(context)!.arenaPompes,
                              pushupsController,
                              arc,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildExerciseInput(
                              AppLocalizations.of(context)!.arenaAbdos,
                              absController,
                              arc,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isSaving)
                        LinearProgressIndicator(
                          color: arc.primaryColor,
                          backgroundColor: arc.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.commonCancel,
                      style: TextStyle(
                        color: arc.onSurfaceColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: arc.primaryColor,
                      disabledBackgroundColor: arc.primaryColor.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    onPressed:
                        isSaving
                            ? null
                            : () async {
                              final d = int.tryParse(dipsController.text) ?? 0;
                              final pu =
                                  int.tryParse(pullupsController.text) ?? 0;
                              final ps =
                                  int.tryParse(pushupsController.text) ?? 0;
                              final ab = int.tryParse(absController.text) ?? 0;
                              final total = d + pu + ps + ab;

                              if (total <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.arenaErreurVousDevezEffectuer,
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setDialogState(() => isSaving = true);

                              try {
                                final user =
                                    ref.read(userProfileProvider).valueOrNull;
                                if (user != null && _userPos != null) {
                                  await ref
                                      .read(valerionRepositoryProvider)
                                      .claimBastion(
                                        bastionId: spot.id,
                                        bastionName: spot.name,
                                        userId: user.id,
                                        pseudo: user.username,
                                        reps: total,
                                        dips: d,
                                        pullups: pu,
                                        pushups: ps,
                                        abs: ab,
                                        exerciseType: "STREET_WORKOUT",
                                        userLat: _userPos!.latitude,
                                        userLng: _userPos!.longitude,
                                      );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: arc.primaryColor,
                                        content: Text(
                                          AppLocalizations.of(context)!.arenaConqueteReussie(total.toString(), spot.name.toUpperCase()),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                    _scanForSpots();
                                  }
                                }
                              } catch (e) {
                                setDialogState(() => isSaving = false);
                                String errorMsg = AppLocalizations.of(context)!.arenaErreurTransmission;
                                if (e.toString().contains("TOO_FAR") ||
                                    e.toString().contains("SIGNAL GPS")) {
                                  errorMsg =
                                      AppLocalizations.of(context)!.arenaEchecSignalGps;
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(errorMsg),
                                    ),
                                  );
                                }
                              }
                            },
                    child: Text(AppLocalizations.of(context)!.arenaConquRir,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildExerciseInput(
    String label,
    TextEditingController controller,
    ArcData arc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: arc.primaryColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: arc.onSurfaceColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: arc.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: arc.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final primaryColor = arc.primaryColor;

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildHeader(primaryColor),
        const SizedBox(height: 20),
        Expanded(
          child:
              _isLoading
                  ? _buildLoadingState(primaryColor)
                  : _spots.isEmpty
                  ? _buildEmptyState(primaryColor)
                  : _buildSpotsList(primaryColor),
        ),
      ],
    );
  }

  Widget _buildHeader(Color color) {
    String nearestInfo =
        _spots.isNotEmpty
            ? AppLocalizations.of(context)!.arenaLePlusProche + _formatDistance(_spots.first.position)
            : AppLocalizations.of(context)!.arenaScanDesStations;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.radar, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.arenaRadarDeBastions,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  nearestInfo,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _scanForSpots,
            icon: Icon(Icons.refresh, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: color),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.arenaProtocoleOsirionScan,
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 60,
            color: color.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.arenaQuartierSCurisAucun,
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotsList(Color color) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _spots.length,
      itemBuilder: (context, index) {
        final spotFromOSM = _spots[index];
        final distStr = _formatDistance(spotFromOSM.position);

        return StreamBuilder<BastionModel?>(
          stream: ref
              .read(valerionRepositoryProvider)
              .listenBastionMetadata(spotFromOSM.id),
          builder: (context, snapshot) {
            // On fusionne les données OSM et Firestore
            final spot =
                snapshot.hasData
                    ? spotFromOSM.merge(snapshot.data!)
                    : spotFromOSM;
            final currentBoss = spot.currentBoss;
            final status = spot.tacticalStatus;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  // --- EN-TÊTE TACTIQUE ---
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: _buildStatusBadge(status),
                    title: Text(
                      spot.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    subtitle: Text(
                      "$distStr • ${AppLocalizations.of(context)!.arenaEstimation}${_getWalkTime(spot.position)}",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ),

                  // --- PHOTO DU SCOUT / OSM ---
                  if (spot.images.isNotEmpty)
                    Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(spot.images.first),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.4),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),

                  // --- L'ARSENAL (ÉQUIPEMENTS) ---
                  if (spot.equipment.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children:
                            spot.equipment
                                .map((e) => _buildEquipmentIcon(e, color))
                                .toList(),
                      ),
                    ),

                  // --- LE RENSEIGNEMENT (INTELLIGENCE) ---
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _getStatusColor(
                                  status,
                                ).withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: _getStatusColor(status),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentBoss != null
                                          ? AppLocalizations.of(context)!.arenaBossPrefix + currentBoss.pseudo.toUpperCase()
                                          : AppLocalizations.of(context)!.arenaZoneVierge,
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (currentBoss != null)
                                      Text(
                                        AppLocalizations.of(context)!.arenaRegneDepuis + _getReignTime(currentBoss.achievedAt),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 8,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                currentBoss != null
                                    ? "${currentBoss.effectiveReps} REPS"
                                    : "---",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (spot.failedAttemptsCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                AppLocalizations.of(context)!.arenaRenseignementEchecs(spot.failedAttemptsCount.toString()),
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (spot.osmNote != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                AppLocalizations.of(context)!.arenaBriefingTactiquePrefix + spot.osmNote!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 7,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // --- ACTIONS ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          Icons.info_outline,
                          AppLocalizations.of(context)!.arenaInfo,
                          color,
                          () => _showBastionInfo(spot),
                        ),
                        _buildActionButton(
                          context,
                          Icons.near_me,
                          AppLocalizations.of(context)!.arenaTracer,
                          color,
                          () {
                            _launchNavigation(spot);
                          },
                        ),
                        _buildActionButton(
                          context,
                          Icons.add_circle,
                          AppLocalizations.of(context)!.arenaDefiAction,
                          _getStatusColor(status),
                          () {
                            if (_userPos == null) return;
                            double distance = Geolocator.distanceBetween(
                              _userPos!.latitude,
                              _userPos!.longitude,
                              spot.position.latitude,
                              spot.position.longitude,
                            );
                            if (distance > 60) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(
                                    AppLocalizations.of(context)!.arenaSignalTropFaibleRapprochez,
                                  ),
                                ),
                              );
                              return;
                            }
                            _claimSpot(spot);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VIERGE':
        return Colors.greenAccent;
      case 'CONFLIT':
        return Colors.yellowAccent;
      case 'FORTERESSE':
        return Colors.redAccent;
      default:
        return Colors.cyanAccent;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _getWalkTime(LatLng pos) {
    if (_userPos == null) return "--";
    double meters = Geolocator.distanceBetween(
      _userPos!.latitude,
      _userPos!.longitude,
      pos.latitude,
      pos.longitude,
    );
    int minutes = (meters / 80).round(); // ~5km/h = 80m/min
    return minutes == 0 ? AppLocalizations.of(context)!.arenaMoinsDuneMinute : AppLocalizations.of(context)!.arenaEnvMinutes(minutes.toString());
  }

  String _getReignTime(DateTime start) {
    final diff = DateTime.now().difference(start);
    if (diff.inDays > 0) return "${diff.inDays} JOURS";
    if (diff.inHours > 0) return "${diff.inHours} HEURES";
    return AppLocalizations.of(context)!.arenaRecent;
  }

  Widget _buildEquipmentIcon(String type, Color color) {
    IconData icon;
    switch (type) {
      case 'BARRE TRACTION':
        icon = Icons.horizontal_rule;
        break;
      case 'BARRES DIPS':
        icon = Icons.reorder;
        break;
      case 'BANC ABDOS':
        icon = Icons.panorama_fish_eye;
        break;
      case 'ANNEAUX':
        icon = Icons.trip_origin;
        break;
      default:
        icon = Icons.fitness_center;
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showBastionInfo(BastionModel spotFromOSM) {
    final arc = ref.read(arcProvider);
    final repository = ref.read(valerionRepositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => StreamBuilder<BastionModel?>(
                  stream: repository.listenBastionMetadata(spotFromOSM.id),
                  builder: (context, snapshot) {
                    // Fusion en temps réel
                    final spot =
                        snapshot.hasData
                            ? spotFromOSM.merge(snapshot.data!)
                            : spotFromOSM;

                    return Container(
                      decoration: BoxDecoration(
                        color: arc.surfaceColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Photo ou Mission de Reconnaissance
                                  if (spot.images.isNotEmpty)
                                    _buildImagesCarousel(spot)
                                  else
                                    _buildReconMissionScanner(
                                      spot,
                                      arc.primaryColor,
                                    ),

                                  // Bouton d'ajout si moins de 4 images
                                  if (spot.images.length < 4)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: InkWell(
                                        onTap: () => _captureBastionIntel(spot),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: arc.primaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: arc.primaryColor
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add_a_photo,
                                                  size: 14,
                                                  color: arc.primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  spot.images.isEmpty
                                                      ? AppLocalizations.of(context)!.arenaTransmettreRenseignement
                                                      : AppLocalizations.of(context)!.arenaCompleterRenseignement(spot.images.length.toString()),
                                                  style: TextStyle(
                                                    color: arc.primaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              spot.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            Text(
                                              spot.type,
                                              style: TextStyle(
                                                color: arc.primaryColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(spot.tacticalStatus),
                                    ],
                                  ),

                                  const SizedBox(height: 32),
                                  _buildInfoSection(
                                    AppLocalizations.of(context)!.arenaArsenalTactique,
                                    Icons.fitness_center,
                                    [
                                      if (spot.equipment.isEmpty)
                                        Text(AppLocalizations.of(context)!.arenaAucunQuipementSpCifique,
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children:
                                              spot.equipment
                                                  .map(
                                                    (e) => Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: arc.primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: arc
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.check_circle,
                                                            size: 12,
                                                            color:
                                                                arc.primaryColor,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            e,
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),
                                  _buildInfoSection(
                                    AppLocalizations.of(context)!.arenaRenseignementAlpha,
                                    Icons.shield,
                                    [
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaBossActuel,
                                        spot.currentBoss?.pseudo ?? AppLocalizations.of(context)!.arenaInconnuCaps,
                                      ),
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaRecordEffort,
                                        spot.currentBoss != null
                                            ? "${spot.currentBoss!.effectiveReps} REPS"
                                            : "---",
                                      ),
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaTempsDeRegne,
                                        spot.currentBoss != null
                                            ? _getReignTime(
                                              spot.currentBoss!.achievedAt,
                                            )
                                            : "---",
                                      ),
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaEchecsRecents,
                                        "${spot.failedAttemptsCount} TENTATIVES",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),
                                  if (spot.osmNote != null)
                                    _buildInfoSection(
                                      AppLocalizations.of(context)!.arenaBriefingTactiqueSansIcone,
                                      Icons.description,
                                      [
                                        Text(
                                          spot.osmNote!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            height: 1.5,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 32),
                                  _buildInfoSection(
                                    AppLocalizations.of(context)!.arenaCoordonneesMission,
                                    Icons.location_on,
                                    [
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaQuartier,
                                        spot.neighborhood ?? AppLocalizations.of(context)!.arenaInconnuCamel,
                                      ),
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaLatitude,
                                        spot.position.latitude.toStringAsFixed(
                                          6,
                                        ),
                                      ),
                                      _buildIntelRow(
                                        AppLocalizations.of(context)!.arenaLongitude,
                                        spot.position.longitude.toStringAsFixed(
                                          6,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: arc.primaryColor
                                                .withValues(alpha: 0.1),
                                            foregroundColor: arc.primaryColor,
                                            side: BorderSide(
                                              color: arc.primaryColor
                                                  .withValues(alpha: 0.2),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed:
                                              () => _launchNavigation(spot),
                                          icon: const Icon(
                                            Icons.near_me,
                                            size: 18,
                                          ),
                                          label: Text(AppLocalizations.of(context)!.arenaPositionSatelliteGuidage,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    final arc = ref.read(arcProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: arc.primaryColor, size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: arc.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildIntelRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCarousel(BastionModel spot) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: spot.images.length,
            onPageChanged:
                (index) => setState(
                  () {},
                ), // Pour forcer le refresh des dots si on utilisait un contrôleur, mais ici on va faire simple avec un State local si besoin. Pour l'instant le badge suffit mais ajoutons des dots statiques ou un indicateur.
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(spot.images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child:
                    spot.images.length > 1
                        ? Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${index + 1}/${spot.images.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        : null,
              );
            },
          ),
        ),
        if (spot.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                spot.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReconMissionScanner(BastionModel spot, Color color) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_enhance, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.arenaMissionDeReconnaissance,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              Text(AppLocalizations.of(context)!.arenaFournissezLeRenseignementVisuel,
                style: TextStyle(color: Colors.white38, fontSize: 8),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _captureBastionIntel(spot),
                icon: const Icon(Icons.camera),
                label: Text(AppLocalizations.of(context)!.arenaCapturerLIntel,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Indicateur de prime (XP)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(AppLocalizations.of(context)!.arena250Xp,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureBastionIntel(BastionModel spot) async {
    final repository = ref.read(valerionRepositoryProvider);
    debugPrint("🚀 Amorçage Mission Reconnaissance pour: ${spot.name}");

    // 1. Vérifier la distance
    Position pos = await Geolocator.getCurrentPosition();
    if (pos.isMocked) {
      _showTacticalAlert(
        title: AppLocalizations.of(context)!.arenaViolationDeSCurit,
        message:
            "L'utilisation de fausses positions GPS (Fake GPS) est strictement interdite par le protocole Osirion.",
        isError: true,
      );
      return;
    }

    if (_userPos == null) {
      debugPrint("❌ Erreur: _userPos est NULL");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            AppLocalizations.of(context)!.arenaErreurSignalGpsPosition,
          ),
        ),
      );
      return;
    }

    double distance = Geolocator.distanceBetween(
      _userPos!.latitude,
      _userPos!.longitude,
      spot.position.latitude,
      spot.position.longitude,
    );
    debugPrint("📍 Distance calculée: ${distance.toInt()}m (Cible: 60m)");

    if (distance > 60) {
      debugPrint("❌ Erreur: Distance trop grande (${distance.toInt()}m)");
      _showTacticalAlert(
        title: AppLocalizations.of(context)!.arenaVousTesTropLoin,
        message:
            "Pour prendre la photo et gagner les XP, vous devez être sur place (à moins de 50m).\n\nVous êtes actuellement à ${distance.toInt()}m du spot.",
        isError: true,
      );
      return;
    }

    debugPrint("✅ Vérification distance OK. Demande permissions...");

    // 2. Vérifier les permissions explicitement (Important pour Android 11+)
    var status = await Permission.camera.status;
    debugPrint("📸 État permission caméra: $status");

    if (status.isDenied) {
      debugPrint("🔓 Demande de permission en cours...");
      status = await Permission.camera.request();
      debugPrint("🔓 Nouveau statut après demande: $status");

      if (status.isDenied) {
        debugPrint("❌ Permission refusée par l'utilisateur.");
        _showTacticalAlert(
          title: AppLocalizations.of(context)!.arenaAutorisationRequise,
          message:
              "L'œil de Valérion (Caméra) doit être activé pour authentifier votre présence sur le Bastion.",
        );
        return;
      }
    }

    if (status.isPermanentlyDenied) {
      debugPrint("🚫 Permission bloquée définitivement. Ouverture settings.");
      openAppSettings();
      return;
    }

    // 3. Ouvrir la caméra
    try {
      debugPrint("📸 Lancement de l'appareil photo (ImageSource.camera)...");
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      debugPrint("📸 Résultat Camera: ${image?.path ?? 'ANNULÉ'}");

      if (image != null) {
        setState(() => _isLoading = true);
        await repository.uploadBastionPhoto(
          bastionId: spot.id,
          filePath: image.path,
          bastionName: spot.name,
          lat: spot.position.latitude,
          lng: spot.position.longitude,
        );
        if (mounted) {
          Navigator.pop(context); // Fermer le hub info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.greenAccent,
              content: Text(
                AppLocalizations.of(context)!.arenaRenseignementTransmis250Xp,
              ),
            ),
          );
          _scanForSpots(); // Rafraîchir
        }
      }
    } catch (e) {
      debugPrint("❌ Erreur Camera/Picker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              "ERREUR SYSTÈME : Impossible d'activer le capteur optique ($e)",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchNavigation(BastionModel spot) async {
    // Utilisation de l'API de direction pour lancer directement le guidage
    final query = "${spot.position.latitude},${spot.position.longitude}";
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=walking",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.arenaImpossibleDeLancerLe),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showTacticalAlert({
    required String title,
    required String message,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF13161C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color:
                    isError
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : Colors.cyanAccent.withValues(alpha: 0.5),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  isError ? Icons.warning_amber : Icons.info_outline,
                  color: isError ? Colors.redAccent : Colors.cyanAccent,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isError ? Colors.redAccent : Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "COMPRIS",
                  style: TextStyle(
                    color: isError ? Colors.redAccent : Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
