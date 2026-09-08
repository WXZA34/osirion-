import '../../l10n/app_localizations.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/providers/arc_provider.dart';
import '../../core/models/lat_lng.dart';
import '../../core/models/tactical_no_go_zone.dart';

import 'services/no_go_zone_service.dart';
import 'services/routing_service.dart';
import 'models/arena_models.dart';
import 'arena_report_screen.dart';
import 'widgets/arena_map.dart' as am;

class ArenaActiveScreen extends ConsumerStatefulWidget {
  final String sportType; // RUNNING, WALKING, CYCLING
  final double targetDistanceKm;
  final ColosseumRunModel? ghostTarget;
  final LatLng? destination;
  final String? destinationName;

  const ArenaActiveScreen({
    super.key,
    required this.sportType,
    required this.targetDistanceKm,
    this.ghostTarget,
    this.destination,
    this.destinationName,
  });

  @override
  ConsumerState<ArenaActiveScreen> createState() => _ArenaActiveScreenState();
}

class _ArenaActiveScreenState extends ConsumerState<ArenaActiveScreen> with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  LatLng? _startPoint;

  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  final ValueNotifier<int> _elapsedSecondsNotifier = ValueNotifier<int>(0);
  final List<LatLng> _routePoints = [];
  double _distanceTraveledKm = 0.0;
  final ValueNotifier<double> _distanceTraveledNotifier = ValueNotifier<double>(
    0.0,
  );
  final List<double> _speedProfile = []; // Distance cumulée toutes les 10s
  double _currentPaceMinPerKm = 0.0; // En minutes par km
  final ValueNotifier<double> _paceNotifier = ValueNotifier<double>(0.0);
  
  // Ghost Dual Logic
  final ValueNotifier<double> _ghostDistanceNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<LatLng?> _ghostPositionNotifier = ValueNotifier<LatLng?>(null);
  bool _isRunning = false;

  List<LatLng> _predictedRoutePoints = [];
  final ValueNotifier<bool> _isGeneratingRouteNotifier = ValueNotifier<bool>(
    false,
  );
  
  // Nouveaux notifiers pour le type de carte et vue 3D
  final ValueNotifier<String> _mapTypeNotifier = ValueNotifier<String>('OUTDOORS');
  final ValueNotifier<bool> _is3DModeNotifier = ValueNotifier<bool>(false); 
  mb.MapboxMap? _mapboxMapController;
  double _currentHeading = 0.0;

  final ValueNotifier<double> _syncPrecisionNotifier = ValueNotifier<double>(
    100.0,
  );
  final ValueNotifier<String> _aiCoachMessageNotifier = ValueNotifier<String>(
    "INITIALISATION IA...",
  );
  double _totalPrecisionAccumulated = 0.0;
  int _precisionChecksCount = 0;

  int _distanceFilterMeters = 3; // Par défaut: haute précision (3m)

  LatLng? _lastCameraPos;
  bool _isInitializing = true;
  String _loadingMessage = "INITIALISATION GPS...";
  bool _isFollowingUser = true; // Auto-follow pour l'effet trilogie

  // --- OPTIMISATION ANR (Protocoles de Stabilité) ---
  int _lastNearestRouteIndex = 0;
  int _lastGhostIndex = 0;
  double _lastGhostAccumulatedDist = 0.0;

  // --- SYSTÈME TACTIQUE (No-Go Zones) ---
  final NoGoZoneService _noGoZoneService = NoGoZoneService();
  List<TacticalNoGoZone> _nearbyNoGoZones = [];
  StreamSubscription? _noGoZonesSub;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkPermissionsAndStart();
  }


  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    double frequency = prefs.getDouble('gps_frequency') ?? 1.0;
    int filter = (15 - (frequency * 12)).round();

    if (mounted) {
      setState(() {
        _distanceFilterMeters = filter.clamp(3, 15);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _noGoZonesSub?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionsAndStart() async {
    setState(() {
      _isInitializing = true;
      _loadingMessage = "VÉRIFICATION PERMISSIONS...";
    });

    final status = await Permission.locationWhenInUse.request();
    
    if (status.isGranted) {
      if (!mounted) return;

      setState(() => _loadingMessage = "RECHERCHE SIGNAL GPS...");

      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("Erreur GPS initiale: $e");
        _currentPosition = await Geolocator.getLastKnownPosition();
      }

      if (_currentPosition != null) {
        if (_currentPosition!.isMocked) {
          _handleGpsCheating();
          return;
        }
        LatLng startPoint = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _routePoints.add(startPoint);

        _initTacticalSurveillance(startPoint);

        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }

        _startWorkout();
        
        if (widget.ghostTarget != null) {
          _loadingMessage = "SYNCHRONISATION RIVAL...";
          _prepareGhostPath(startPoint);
        } else if (widget.destination != null) {
          _loadingMessage = "TRACE DE L'OBJECTIF...";
          _generatePathToDestination(startPoint, widget.destination!);
        } else {
          _generateLoopRoute(startPoint);
        }
      } else {
        _showErrorDialog(
          "SIGNAL GPS INTROUVABLE",
          "Impossible de localiser votre position. Assurez-vous d'être à l'extérieur avec une vue dégagée sur le ciel."
        );
      }
    } else if (status.isPermanentlyDenied) {
      _showErrorDialog(
        "ACCÈS GÉOLOCALISATION REQUIS",
        "L'Arène a besoin de votre position pour fonctionner. Veuillez activer l'accès dans les paramètres de votre téléphone."
      );
    } else {
      _showErrorDialog(
        "PERMISSION REFUSÉE",
        "L'accès à la localisation a été refusé. Impossible de lancer la session."
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    setState(() => _isInitializing = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13161C),
        title: Text(title, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.commonReturn, style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _startWorkout() {
    setState(() {
      _isRunning = true;
      _startPoint = _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRunning) {
        _elapsedSecondsNotifier.value++;
        
        // Capture du SpeedProfile toutes les 10 secondes
        if (_elapsedSecondsNotifier.value % 10 == 0) {
          _speedProfile.add(_distanceTraveledKm);
        }
        
        if (widget.ghostTarget != null) {
          _updateGhostDistance(_elapsedSecondsNotifier.value);
        }
        
        _updatePace();
      }
    });

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: _distanceFilterMeters,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted && _isRunning) {
        if (position.isMocked) {
          _handleGpsCheating();
          return;
        }
        LatLng newPoint = LatLng(position.latitude, position.longitude);

        if (_routePoints.isNotEmpty) {
          LatLng lastPoint = _routePoints.last;
          double distInMeters = Geolocator.distanceBetween(
            lastPoint.latitude,
            lastPoint.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
          _distanceTraveledKm += (distInMeters / 1000.0);
          _distanceTraveledNotifier.value = _distanceTraveledKm;
        }

        _routePoints.add(newPoint);
        _currentPosition = position;
        _currentHeading = position.heading;

        double moveDist = 100.0;
        if (_lastCameraPos != null) {
          moveDist = Geolocator.distanceBetween(
            _lastCameraPos!.latitude,
            _lastCameraPos!.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
        }
        if (moveDist >= 10.0) {
          _lastCameraPos = newPoint;
          // Fluidité numéro 3 : Suivi Drone (easeTo)
          if (_isFollowingUser) {
            _smoothFollowUser(newPoint, position.heading);
          }
        }
        _updateLoopPrecision(newPoint);
      }
    });
  }

  void _smoothFollowUser(LatLng point, double heading) {
    if (_mapboxMapController == null) return;
    
    _mapboxMapController?.easeTo(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(point.longitude, point.latitude)),
        bearing: heading, // Aligne la caméra sur la direction (Fluidité)
        zoom: 15.5,
        pitch: _is3DModeNotifier.value ? 60.0 : 0.0,
      ),
      mb.MapAnimationOptions(duration: 1500), // Adoucissement 1.5s
    );
  }

  void _toggle3DMode() {
    _is3DModeNotifier.value = !_is3DModeNotifier.value;
  }

  DateTime _lastPrecisionCheck = DateTime.now();

  void _toggleMapType() {
    const styles = ['STANDARD', 'LIGHT', 'OUTDOORS', 'SATELLITE'];
    int currentIndex = styles.indexOf(_mapTypeNotifier.value);
    if (currentIndex == -1) currentIndex = 0;
    _mapTypeNotifier.value = styles[(currentIndex + 1) % styles.length];
  }

  void _updateLoopPrecision(LatLng currentPos) {
    if (_predictedRoutePoints.isEmpty) return;

    final now = DateTime.now();
    if (now.difference(_lastPrecisionCheck).inMilliseconds < 1000) return;
    _lastPrecisionCheck = now;

    int routeLen = _predictedRoutePoints.length;
    double minDistance = double.infinity;
    int bestIndex = _lastNearestRouteIndex;

    // Recherche optimisée par voisinage (± 100 points autour du dernier connu)
    // Cela transforme un calcul O(N) en O(const) une fois lancé.
    int startIdx = (bestIndex - 50).clamp(0, routeLen - 1);
    int endIdx = (bestIndex + 100).clamp(startIdx, routeLen - 1);

    // Si on est vraiment loin ou au début, on scanne un peu plus large (fallback stabilité)
    if (bestIndex == 0 || startIdx == 0) endIdx = math.min(routeLen - 1, 300);

    for (int i = startIdx; i <= endIdx; i++) {
      final point = _predictedRoutePoints[i];
      double d = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        point.latitude,
        point.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        bestIndex = i;
        if (d < 5) break; 
      }
    }

    _lastNearestRouteIndex = bestIndex;

    double precision = 100.0;
    if (minDistance > 15) {
      precision = (100.0 - ((minDistance - 15) / 1.35)).clamp(0.0, 100.0);
    }

    _syncPrecisionNotifier.value = precision;
    _totalPrecisionAccumulated += precision;
    _precisionChecksCount++;

    String statusPrefix = "";
    if (widget.sportType == 'RUNNING') {
      statusPrefix = "ASSAUT : ";
      if (precision > 90) {
        _aiCoachMessageNotifier.value = "${statusPrefix}PERFORMANCE ALPHA MAX";
      } else if (precision > 70) {
        _aiCoachMessageNotifier.value = "${statusPrefix}CADENCE MAINTENUE";
      } else {
        _aiCoachMessageNotifier.value = "${statusPrefix}DÉFAILLANCE RYTHMIQUE";
      }
    } else if (widget.sportType == 'CYCLING') {
      statusPrefix = "TACTIQUE : ";
      if (precision > 90) {
        _aiCoachMessageNotifier.value = "${statusPrefix}VECTEUR OPTIMAL";
      } else if (precision > 70) {
        _aiCoachMessageNotifier.value = "${statusPrefix}TRANSITION STABLE";
      } else {
        _aiCoachMessageNotifier.value = "${statusPrefix}RECALCUL TRAJECTOIRE";
      }
    } else {
      statusPrefix = "RECO : ";
      if (precision > 90) {
        _aiCoachMessageNotifier.value = "${statusPrefix}SYNCHRO ALPHA OPTIMALE";
      } else if (precision > 70) {
        _aiCoachMessageNotifier.value = "${statusPrefix}ALIGNEMENT STABLE";
      } else {
        _aiCoachMessageNotifier.value = "${statusPrefix}DÉRIVE ALPHA DÉTECTÉE";
      }
    }
  }

  void _stopWorkout() {
    setState(() => _isRunning = false);
    _timer?.cancel();
    _positionStream?.cancel();

    double averagePace = 0.0;
    if (_distanceTraveledKm > 0) {
      averagePace = (_elapsedSecondsNotifier.value / 60.0) / _distanceTraveledKm;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ArenaReportScreen(
          sportType: widget.sportType,
          distanceKm: _distanceTraveledKm,
          durationSeconds: _elapsedSecondsNotifier.value,
          averagePaceMinPerKm: averagePace,
          syncPrecision: _precisionChecksCount > 0 ? (_totalPrecisionAccumulated / _precisionChecksCount) : 100.0,
          path: List.from(_routePoints),
          speedProfile: List.from(_speedProfile),
        ),
      ),
    );
  }

  void _centerCamera() {
    if (_mapboxMapController == null || _currentPosition == null) return;
    
    _isFollowingUser = true; // Réactiver l'auto-follow

    _mapboxMapController?.flyTo(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(_currentPosition!.longitude, _currentPosition!.latitude)),
        zoom: 15.5,
        pitch: _is3DModeNotifier.value ? 60.0 : 0.0,
        bearing: _currentHeading,
      ),
      mb.MapAnimationOptions(duration: 1000),
    );
  }

  void _updatePace() {
    if (_distanceTraveledKm > 0.05) {
      double totalMinutes = _elapsedSecondsNotifier.value / 60.0;
      _currentPaceMinPerKm = totalMinutes / _distanceTraveledKm;
      _paceNotifier.value = _currentPaceMinPerKm;
    }
  }

  void _handleGpsCheating() {
    _timer?.cancel();
    _positionStream?.cancel();
    setState(() => _isRunning = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13161C),
        title: Text(AppLocalizations.of(context)!.arenaAnomalieDTectE,
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(AppLocalizations.of(context)!.arenaLUtilisationDUne,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "COMPRIS",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }



  void _updateGhostDistance(int seconds) {
    if (widget.ghostTarget == null || widget.ghostTarget!.speedProfile.isEmpty) return;

    final profile = widget.ghostTarget!.speedProfile;
    // Index 0 = 10s, Index 1 = 20s...
    int index = (seconds ~/ 10) - 1;
    
    if (index < 0) {
      double targetAt10s = profile[0];
      _ghostDistanceNotifier.value = (targetAt10s / 10.0) * seconds;
    } else if (index >= profile.length - 1) {
      _ghostDistanceNotifier.value = profile.last;
    } else {
      double startDist = profile[index];
      double endDist = profile[index + 1];
      double ratio = (seconds % 10) / 10.0;
      _ghostDistanceNotifier.value = startDist + (endDist - startDist) * ratio;
    }

    // Mise à jour de la position visuelle du Ghost
    if (_predictedRoutePoints.isNotEmpty) {
      _ghostPositionNotifier.value = _getPositionAtDistance(
        _predictedRoutePoints, 
        _ghostDistanceNotifier.value
      );
    }
  }

  LatLng _getPositionAtDistance(List<LatLng> path, double distanceKm) {
    if (path.isEmpty) return const LatLng(0, 0);
    if (distanceKm <= 0) return path.first;

    double accumulated = 0.0;
    
    // Optimisation : départ depuis le dernier index connu
    int startIdx = _lastGhostIndex;
    if (distanceKm < _lastGhostAccumulatedDist) {
      startIdx = 0;
      accumulated = 0.0;
    } else {
      accumulated = _lastGhostAccumulatedDist;
    }

    for (int i = startIdx; i < path.length - 1; i++) {
      double d = Geolocator.distanceBetween(
        path[i].latitude, path[i].longitude,
        path[i+1].latitude, path[i+1].longitude,
      ) / 1000.0;

      if (accumulated + d >= distanceKm) {
        _lastGhostIndex = i;
        _lastGhostAccumulatedDist = accumulated;
        double ratio = (distanceKm - accumulated) / d;
        return LatLng(
          path[i].latitude + (path[i+1].latitude - path[i].latitude) * ratio,
          path[i].longitude + (path[i+1].longitude - path[i].longitude) * ratio,
        );
      }
      accumulated += d;
    }

    _lastGhostIndex = path.length - 1;
    _lastGhostAccumulatedDist = accumulated;
    return path.last;
  }

  void _prepareGhostPath(LatLng userStart) {
    if (widget.ghostTarget == null) return;
    // On génère la boucle locale sur laquelle le fantôme sera projété
    _generateLoopRoute(userStart);
  }


  Future<void> _generateLoopRoute(LatLng startPoint) async {
    _isGeneratingRouteNotifier.value = true;
    final seed = math.Random().nextInt(100000);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final trustedZones = _noGoZoneService.filterTrustedZones(_nearbyNoGoZones, userId);
      final avoidCoords = trustedZones.map((z) => LatLng(z.location.geopoint.latitude, z.location.geopoint.longitude)).toList();

      final List<LatLng> fullRoute = await RoutingService.calculateCircularRoute(
        startPoint,
        widget.targetDistanceKm,
        widget.sportType,
        seed: seed,
        obstacles: avoidCoords,
      );

      if (fullRoute.isNotEmpty && mounted) {
        setState(() {
          _predictedRoutePoints = fullRoute;
        });
      }
    } catch (e) {
      debugPrint("Erreur RoutingService: $e");
    } finally {
      if (mounted) {
        _isGeneratingRouteNotifier.value = false;
        setState(() {});
      }
    }
  }
  Future<void> _generatePathToDestination(LatLng start, LatLng end) async {
    _isGeneratingRouteNotifier.value = true;
    try {
      // Mise à jour de l'appel pour utiliser la nouvelle signature (Liste de points)
      final List<LatLng> path = await RoutingService.getDirections([start, end], widget.sportType);
      if (path.isNotEmpty && mounted) {
        setState(() {
          _predictedRoutePoints = path;
        });
      }
    } catch (e) {
      debugPrint("Erreur Navigation Spot: $e");
    } finally {
      if (mounted) {
        _isGeneratingRouteNotifier.value = false;
        setState(() {});
      }
    }
  }

  void _initTacticalSurveillance(LatLng startPoint) {
    _noGoZonesSub?.cancel();
    final geoPoint = GeoPoint(startPoint.latitude, startPoint.longitude);
    
    _noGoZonesSub = _noGoZoneService.watchNearbyZones(geoPoint, radiusKm: 5.0).listen((zones) {
      if (mounted) {
        setState(() {
          _nearbyNoGoZones = zones;
        });
        
        // --- LOGIQUE DE RECALCUL DYNAMIQUE ---
        _checkAndRerouteIfNeeded(zones);
      }
    });
  }

  void _checkAndRerouteIfNeeded(List<TacticalNoGoZone> zones) {
    if (_predictedRoutePoints.isEmpty) return;
    
    // On ne recalcule que si un nouvel obstacle critique (validé) apparaît
    // sur le trajet restant (après l'index actuel).
    int startScan = _lastNearestRouteIndex;
    
    for (var zone in zones) {
      // On scanne les points à venir sur l'itinéraire
      for (int i = startScan; i < _predictedRoutePoints.length; i++) {
        final point = _predictedRoutePoints[i];
        final distance = Geolocator.distanceBetween(
          zone.location.latitude, zone.location.longitude,
          point.latitude, point.longitude
        );
        
        if (distance < 50.0) {
          // OBSTACLE DÉTECTÉ SUR LE CHEMIN FUTUR !
          _triggerTacticalReroute();
          return;
        }
      }
    }
  }

  Future<void> _triggerTacticalReroute() async {
    if (_currentPosition == null || _isGeneratingRouteNotifier.value || _startPoint == null) return;
    
    debugPrint("TACTICAL REROUTE TRIGGERED");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.arenaAlerteZoneCompromiseRecalcul, 
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        duration: Duration(seconds: 4),
      ),
    );

    final currentPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    
    // 1. Calcul de la distance restante prévue
    double totalRemainingDist = (widget.targetDistanceKm - _distanceTraveledKm).clamp(0.1, widget.targetDistanceKm);
    
    // 2. Calcul de la distance de retour direct vers le départ
    double distToStart = Geolocator.distanceBetween(
      currentPos.latitude, currentPos.longitude,
      _startPoint!.latitude, _startPoint!.longitude
    ) / 1000.0;

    // 3. La distance qu'on peut "dépenser" dans une boucle de diversion
    double loopDist = totalRemainingDist - distToStart;

    if (loopDist > 0.5) {
      // On génère une boucle de diversion, puis on rentre à la maison
      await _generateRemainingRoute(currentPos, loopDist);
    } else {
      // Trop proche de la fin ou du départ : retour direct
      await _generatePathToDestination(currentPos, _startPoint!);
    }
  }

  Future<void> _generateRemainingRoute(LatLng currentPos, double loopDist) async {
    if (_startPoint == null) return;
    _isGeneratingRouteNotifier.value = true;
    final seed = math.Random().nextInt(100000);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final trustedZones = _noGoZoneService.filterTrustedZones(_nearbyNoGoZones, userId);
      final avoidCoords = trustedZones.map((z) => LatLng(z.location.geopoint.latitude, z.location.geopoint.longitude)).toList();

      // A. On génère d'abord la boucle de diversion
      final List<LatLng> diversionLoop = await RoutingService.calculateCircularRoute(
        currentPos,
        loopDist,
        widget.sportType,
        seed: seed,
        obstacles: avoidCoords,
      );

      // B. On génère le trajet de retour depuis la fin de la boucle (qui est currentPos) vers le départ
      final List<LatLng> returnPath = await RoutingService.getDirections([currentPos, _startPoint!], widget.sportType);

      if (mounted) {
        setState(() {
          // Si la boucle échoue, on utilise au moins le trajet de retour
          if (diversionLoop.isNotEmpty) {
            _predictedRoutePoints = [...diversionLoop, ...returnPath];
          } else {
            _predictedRoutePoints = returnPath;
          }
          _lastNearestRouteIndex = 0; 
        });
      }
    } catch (e) {
      debugPrint("Erreur Rerouting Tactique: $e");
    } finally {
      if (mounted) {
        _isGeneratingRouteNotifier.value = false;
        setState(() {});
      }
    }
  }

  Future<void> _handleTacticalUplink() async {
    if (_currentPosition == null) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final point = GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.arenaSignalementEnvoyUplinkTactique, style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
      ),
    );
    
    await _noGoZoneService.reportObstacle(point, userId);
  }

  @override
  Widget build(BuildContext context) {
    final arc = ref.watch(arcProvider);
    final accentColor = arc.primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CARTE EN FOND (100% de l'écran)
          _buildMap(accentColor),
          _buildTopBar(accentColor),
          _buildCyberHUD(accentColor),
          if (_isInitializing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.arenaVRificationDesProtocoles,
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(Color accentColor) {
    return ValueListenableBuilder<String>(
      valueListenable: _mapTypeNotifier,
      builder: (context, mapType, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _is3DModeNotifier,
          builder: (context, is3DModeActive, _) {
            return ValueListenableBuilder<LatLng?>(
              valueListenable: _ghostPositionNotifier,
              builder: (context, ghostPos, _) {
                return am.ArenaMap(
                  generatedLoop: _predictedRoutePoints,
                  userPosition: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                      : null,
                  obstacles: _nearbyNoGoZones.map((z) => LatLng(z.location.latitude, z.location.longitude)).toList(),
                  mapType: mapType,
                  is3DMode: is3DModeActive,
                  bearing: _currentHeading,
                  ghostPosition: ghostPos,
                  onMapCreated: (map) => _mapboxMapController = map,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(Color accentColor) {
    return Stack(
      children: [
        // 1. DÉGRADÉ SUPÉRIEUR (PROTECTION LISIBILITÉ)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // 2. BOUTON FERMER (TOP LEFT)
        Positioned(
          top: 10,
          left: 20,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.close, color: accentColor, size: 24),
              ),
            ),
          ),
        ),

        // 3. TIMER (TOP CENTER)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: widget.sportType == 'RUNNING' ? Colors.redAccent : accentColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.sportType == 'RUNNING' ? Colors.redAccent : accentColor).withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _elapsedSecondsNotifier,
                  builder: (context, seconds, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.sportType == 'RUNNING') ...[
                          const Icon(Icons.flash_on, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatTime(seconds),
                          style: TextStyle(
                            color: widget.sportType == 'RUNNING' ? Colors.redAccent : accentColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // 4. COLONNE DE CONTRÔLE CARTE (RIGHT SIDE)
        Positioned(
          top: 10,
          right: 20,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapButton(Icons.my_location, _centerCamera, accentColor),
                const SizedBox(height: 12),
                _buildMapButton(Icons.layers, _toggleMapType, accentColor),
                const SizedBox(height: 12),
                _build3DButton(accentColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap, Color accentColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: accentColor, size: 24),
      ),
    );
  }

  Widget _build3DButton(Color accentColor) {
    return GestureDetector(
      onTap: _toggle3DMode,
      child: ValueListenableBuilder<bool>(
        valueListenable: _is3DModeNotifier,
        builder: (context, is3D, _) {
          return Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: is3D ? accentColor.withValues(alpha: 0.2) : Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(
                color: is3D ? accentColor : accentColor.withValues(alpha: 0.5),
                width: is3D ? 2 : 1,
              ),
            ),
            child: Text(
              "3D",
              style: TextStyle(
                color: is3D ? accentColor : accentColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildCyberHUD(Color accentColor) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        children: [
          if (widget.ghostTarget != null) _buildDuelHUD(accentColor),
          const SizedBox(height: 12),
          // Tactical Uplink (No-Go Zones)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildTacticalUplinkButton(accentColor),
            ),
          ),
          // Bouton d'action principal (Start/Stop)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isRunning ? _stopWorkout : _startWorkout,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isRunning ? Colors.redAccent.withValues(alpha: 0.2) : Colors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isRunning ? Colors.redAccent : Colors.cyanAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRunning ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRunning ? Icons.stop : Icons.play_arrow,
                        color: _isRunning ? Colors.redAccent : Colors.cyanAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isRunning ? "TERMINER MISSION" : "DÉMARRER L'ASSAUT",
                        style: TextStyle(
                          color: _isRunning ? Colors.redAccent : Colors.cyanAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _distanceTraveledNotifier,
                    builder: (context, distance, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            distance.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "KM",
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                    Text(
                      widget.sportType == 'RUNNING' 
                          ? "MODE ASSAUT : ${widget.targetDistanceKm.toStringAsFixed(1)} KM"
                          : widget.sportType == 'CYCLING'
                              ? "EXPLORATION TACTIQUE : ${widget.targetDistanceKm.toStringAsFixed(1)} KM"
                              : "RECONNAISSANCE : ${widget.targetDistanceKm.toStringAsFixed(1)} KM",
                      style: TextStyle(
                        color: widget.sportType == 'RUNNING' ? Colors.redAccent.withValues(alpha: 0.8) : accentColor.withValues(alpha: 0.5),
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: _aiCoachMessageNotifier,
                    builder: (context, message, child) {
                      return _PulseText(
                        text: message,
                        color: message.contains("SYNCHRO") ? Colors.greenAccent : Colors.orangeAccent,
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<double>(
                    valueListenable: _syncPrecisionNotifier,
                    builder: (context, precision, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (precision > 80 ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: (precision > 80 ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "SYNC IA: ${precision.toInt()}%",
                          style: TextStyle(
                            color: precision > 80 ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalUplinkButton(Color accentColor) {
    return GestureDetector(
      onTap: _handleTacticalUplink,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
      ),
    );
  }

  Widget _buildDuelHUD(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.arenaRivalGhost,
                  style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ValueListenableBuilder<double>(
                valueListenable: _ghostDistanceNotifier,
                builder: (context, ghostDist, _) {
                  double diff = _distanceTraveledKm - ghostDist;
                  bool ahead = diff >= 0;
                  return Text(
                    "${ahead ? '+' : ''}${diff.toStringAsFixed(2)} KM",
                    style: TextStyle(
                        color: ahead ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _ghostDistanceNotifier,
                builder: (context, dist, _) {
                  double progress = (dist / widget.targetDistanceKm).clamp(0.0, 1.0);
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                  );
                },
              ),
              ValueListenableBuilder<double>(
                valueListenable: _distanceTraveledNotifier,
                builder: (context, dist, _) {
                  double progress = (dist / widget.targetDistanceKm).clamp(0.0, 1.0);
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 8)],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseText extends StatefulWidget {
  final String text;
  final Color color;

  const _PulseText({required this.text, required this.color});

  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: [
            Shadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
      ),
    );
  }
}
