import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import '../../../core/services/weather_service.dart';

// Modèle pour le résultat du Smart Trigger
class SmartTriggerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double temperature;
  final bool isRaining;
  final String targetRoute; // "ARENA" ou "DOJO"
  final String cityName;

  SmartTriggerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.temperature,
    required this.isRaining,
    required this.targetRoute,
    required this.cityName,
  });
}

// Provider asynchrone qui calcule la recommandation
final smartTriggerProvider = FutureProvider<SmartTriggerData>((ref) async {
  double lat = 48.8566; // Paris par défaut
  double lon = 2.3522;
  String cityName = "OSIRION HUB";

  try {
    // Essayer de récupérer la position GPS sans bloquer indéfiniment
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy:
                LocationAccuracy.low, // Précision faible pour être très rapide
            timeLimit: Duration(seconds: 3),
          ),
        );
        lat = position.latitude;
        lon = position.longitude;

        // Récupérer le nom de la ville (Reverse Geocoding)
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            cityName = placemarks.first.locality ?? "LOCALISATION ALPHA";
          }
        } catch (e) {
          // Fallback ville
        }
      }
    }
  } catch (e) {
    // Ignorer si échec (garder position par défaut)
  }

  // Obtenir la météo
  final weatherData = await WeatherService.getCurrentWeather(lat, lon);
  final isRaining = weatherData['is_raining'] as bool;
  final temperature = weatherData['temperature'] as double;

  // Obtenir l'heure
  final hour = DateTime.now().hour;

  String title;
  String subtitle;
  IconData icon;
  Color color;
  String targetRoute;

  // LOGIQUE DE RECOMMANDATION
  if (hour >= 5 && hour < 12) {
    // MATIN
    if (isRaining) {
      title = "REPLI TACTIQUE";
      subtitle = "Pluie détectée. Session Dojo recommandée.";
      icon = Icons.health_and_safety;
      color = Colors.blueGrey;
      targetRoute = "DOJO";
    } else {
      title = "DÉFRICHER L'AUBE";
      subtitle = "Temps clair. Courir dans l'Arène.";
      icon = Icons.directions_run;
      color = Colors.orangeAccent;
      targetRoute = "ARENA";
    }
  } else if (hour >= 12 && hour < 18) {
    // APRÈS-MIDI
    title = "FOCUS MENTAL / MOBILITÉ";
    subtitle = "Idéal pour l'apprentissage et le stretching.";
    icon = Icons.self_improvement;
    color = Colors.tealAccent;
    targetRoute = "DOJO"; 
  } else {
    // SOIR
    if (temperature < 10) {
      title = "LA FORGE DU SOIR (AU CHAUD)";
      subtitle = "Il fait froid (${temperature.toStringAsFixed(1)}°C). Objectif: Force.";
      icon = Icons.whatshot;
      color = Colors.deepOrangeAccent;
      targetRoute = "DOJO";
    } else {
      title = "LA FORGE DU SOIR";
      subtitle = "Entraînement de force (Dojo) ou Arène nocturne.";
      icon = Icons.fitness_center;
      color = Colors.cyan;
      targetRoute = "DOJO";
    }
  }

  return SmartTriggerData(
    title: title,
    subtitle: subtitle,
    icon: icon,
    color: color,
    temperature: temperature,
    isRaining: isRaining,
    targetRoute: targetRoute,
    cityName: cityName,
  );
});
