import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:valerion/core/models/lat_lng.dart';

/// Provider qui expose la position GPS de l'utilisateur sous forme de LatLng.
/// Écoute en continu les changements de position.
final userLocationProvider = StreamProvider<LatLng?>((ref) {
  // Configuration du stream de position
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10, // Mise à jour tous les 10 mètres
  );

  return Geolocator.getPositionStream(locationSettings: locationSettings)
      .map((position) => LatLng(position.latitude, position.longitude))
      .handleError((error) {
    debugPrint("❌ Erreur de localisation : $error");
    return null;
  });
});

/// Provider auxiliaire pour obtenir la dernière position connue (fallback)
final lastKnownLocationProvider = FutureProvider<LatLng?>((ref) async {
  try {
    final position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
  } catch (e) {
    debugPrint("❌ Erreur lastKnownLocation : $e");
  }
  return null;
});
