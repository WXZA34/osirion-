import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:valerion/core/models/lat_lng.dart';
import 'package:geocoding/geocoding.dart';
import '../models/arena_models.dart';
import 'package:valerion/core/constants/app_constants.dart';

class PoiService {
  static Future<List<BastionModel>> findWorkoutSpots(LatLng center, double radiusInMeters) async {
    final String url = AppConstants.overpassUrl;
    
    // Requête Overpass QL pour trouver les stations de fitness et spots de workout
    // On cherche les nodes et les areas taggués leisure=fitness_station
    final String query = '''
    [out:json][timeout:25];
    (
      node["leisure"="fitness_station"](around:${radiusInMeters.toInt()},${center.latitude},${center.longitude});
      way["leisure"="fitness_station"](around:${radiusInMeters.toInt()},${center.latitude},${center.longitude});
      node["sport"="street_workout"](around:${radiusInMeters.toInt()},${center.latitude},${center.longitude});
    );
    out body;
    >;
    out skel qt;
    ''';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {"data": query},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> elements = decoded['elements'];
        
        List<Future<BastionModel>> spotFutures = [];
        
        for (var element in elements) {
          if (element['type'] == 'node') {
            final lat = element['lat'] as double;
            final lon = element['lon'] as double;
            final tags = element['tags'] ?? {};
            
            spotFutures.add(() async {
              // 1. Récupérer le quartier/secteur
              final String neighborhood = await _getNeighborhoodName(tags, lat, lon);
              
              // 2. Générer le nom
              String? name = tags['name'] ?? tags['description'];
              if (name == null || name.isEmpty) {
                name = "BASTION SECTEUR ${neighborhood.toUpperCase()}";
              }
              
              return BastionModel(
                id: element['id'].toString(),
                name: name.toUpperCase(),
                position: LatLng(lat, lon),
                type: _inferType(tags),
                leaderboard: [],
                equipment: _extractEquipment(tags),
                neighborhood: neighborhood,
                images: (tags['image'] ?? tags['mapillary'] ?? _getWikimediaThumbnail(tags['wikimedia_commons'])) != null 
                    ? [tags['image'] ?? tags['mapillary'] ?? _getWikimediaThumbnail(tags['wikimedia_commons'])] 
                    : [],
                osmNote: tags['note'] ?? tags['description'],
              );
            }());
          }
        }
        return await Future.wait(spotFutures);
      }
    } catch (e) {
      debugPrint("PoiService Error: $e");
    }
    
    return [];
  }

  static Future<String> _getNeighborhoodName(Map<dynamic, dynamic> tags, double lat, double lon) async {
    // 1. Tenter les tags OSM d'abord (plus rapide)
    final String? osmSuburb = tags['addr:suburb'] ?? tags['suburb'] ?? tags['neighbourhood'];
    if (osmSuburb != null && osmSuburb.isNotEmpty) return osmSuburb;

    // 2. Tenter le géocodage inverse si OSM est vide (avec timeout strict)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon)
          .timeout(const Duration(seconds: 3));
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        // On cherche le plus précis au moins précis
        if (pm.subLocality != null && pm.subLocality!.isNotEmpty) return pm.subLocality!;
        if (pm.thoroughfare != null && pm.thoroughfare!.isNotEmpty) return pm.thoroughfare!;
        if (pm.locality != null && pm.locality!.isNotEmpty) return pm.locality!;
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }

    return "ALPHA";
  }

  static String? _getWikimediaThumbnail(String? commonsPath) {
    if (commonsPath == null) return null;
    // Format simple pour obtenir un aperçu de Wikimedia Commons
    // File:MyPhoto.jpg -> URL de preview
    final fileName = commonsPath.replaceAll('File:', '').replaceAll(' ', '_');
    return "https://commons.wikimedia.org/wiki/Special:FilePath/$fileName?width=500";
  }

  static List<String> _extractEquipment(Map<dynamic, dynamic> tags) {
    List<String> equipment = [];
    final String description = (tags['description'] ?? "").toLowerCase();
    
    if (description.contains("pull up") || description.contains("traction") || tags['check_date:pull_up_bar'] != null) {
      equipment.add("BARRE TRACTION");
    }
    if (description.contains("dip") || description.contains("parallèle") || tags['check_date:parallel_bars'] != null) {
      equipment.add("BARRES DIPS");
    }
    if (description.contains("bench") || description.contains("banc")) {
      equipment.add("BANC ABDOS");
    }
    if (description.contains("ring") || description.contains("anneau")) {
      equipment.add("ANNEAUX");
    }
    
    return equipment;
  }

  static String _inferType(Map<dynamic, dynamic> tags) {
    if (tags['leisure'] == 'fitness_station') return "STATION FITNESS";
    if (tags['sport'] == 'street_workout') return "STREET WORKOUT";
    return "SPOT VALERION";
  }
}
