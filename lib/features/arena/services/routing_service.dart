import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:valerion/core/models/lat_lng.dart';
import 'package:valerion/core/constants/app_constants.dart';

class RoutingService {
  static Future<List<LatLng>> calculateCircularRoute(
    LatLng start,
    double targetDistanceKm,
    String sportType, {
    int? seed,
    List<LatLng>? obstacles,
  }) async {
    final random = math.Random();
    int effectveSeed = seed ?? random.nextInt(100000);
    String profile = (sportType == 'CYCLING') ? 'cycling-regular' : 'foot-walking';
    
    // Préparation des polygones d'évitement (30x30m)
    Map<String, dynamic>? avoidPolygons;
    if (obstacles != null && obstacles.isNotEmpty) {
      avoidPolygons = _generateAvoidPolygons(obstacles);
    }

    // 1. Tenter avec évitement des routes (look propre)
    List<LatLng> route = await _fetchORSRoute(start, targetDistanceKm, profile, effectveSeed, true, avoidPolygons);
    
    // 2. Fallback : Si vide, tenter sans évitement (mieux vaut une route imparfaite que rien)
    if (route.isEmpty) {
      debugPrint("RoutingService: Fallback sans évitement...");
      route = await _fetchORSRoute(start, targetDistanceKm, profile, effectveSeed, false, avoidPolygons);
    }
    
    return route;
  }

  static Future<List<LatLng>> _fetchORSRoute(
    LatLng start, 
    double distanceKm, 
    String profile, 
    int seed,
    bool avoidHighways,
    Map<String, dynamic>? avoidPolygons,
  ) async {
    final String url = 'https://api.openrouteservice.org/v2/directions/$profile/geojson';
    
    final body = json.encode({
      "coordinates": [[start.longitude, start.latitude]],
      "options": {
        "round_trip": {
          "length": (distanceKm * 1000).toInt(),
          "points": 3,
          "seed": seed
        },
        if (avoidHighways) "avoid_features": ["highways", "tollways"],
        if (avoidPolygons != null) "avoid_polygons": avoidPolygons
      }
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': AppConstants.orsApiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['features'] != null && (decoded['features'] as List).isNotEmpty) {
          final feature = decoded['features'][0];
          final List<dynamic> coords = feature['geometry']['coordinates'];
          return coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
        }
      } else {
        debugPrint("ORS Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("RoutingService Network Error: $e");
    }
    return [];
  }

  static Future<List<LatLng>> getDirections(List<LatLng> points, String sportType) async {
    if (points.length < 2) return [];
    
    String profile = (sportType == 'CYCLING') ? 'cycling' : (sportType == 'DRIVING' ? 'driving' : 'walking');
    
    String coordsStr = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    final String url = 'https://api.mapbox.com/directions/v5/mapbox/$profile/$coordsStr?geometries=geojson&access_token=${AppConstants.mapboxAccessToken}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['routes'] != null && (decoded['routes'] as List).isNotEmpty) {
          final List<dynamic> coords = decoded['routes'][0]['geometry']['coordinates'];
          return coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
        }
      }
    } catch (e) {
      debugPrint("Mapbox Routing Error: $e");
    }
    return [];
  }

  static Map<String, dynamic> _generateAvoidPolygons(List<LatLng> centers) {
    List<List<List<List<double>>>> multiCoords = [];
    for (var center in centers) {
      double deltaLat = 15.0 / 111111.0;
      double deltaLng = 15.0 / (111111.0 * math.cos(center.latitude * math.pi / 180.0));
      multiCoords.add([[
        [center.longitude - deltaLng, center.latitude + deltaLat],
        [center.longitude + deltaLng, center.latitude + deltaLat],
        [center.longitude + deltaLng, center.latitude - deltaLat],
        [center.longitude - deltaLng, center.latitude - deltaLat],
        [center.longitude - deltaLng, center.latitude + deltaLat],
      ]]);
    }
    return {"type": "MultiPolygon", "coordinates": multiCoords};
  }
}
