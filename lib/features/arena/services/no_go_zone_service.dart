import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:valerion/core/models/tactical_no_go_zone.dart';

class NoGoZoneService {

  final _collection = FirebaseFirestore.instance.collection('tactical_no_go_zones');

  /// Signale une nouvelle zone d'évitement
  Future<void> reportObstacle(GeoPoint point, String userId) async {
    final geoFirePoint = GeoFirePoint(point);
    final zone = TacticalNoGoZone(
      id: '', // Firestore générera l'ID
      location: geoFirePoint,
      reportedBy: userId,
      trustLevel: 1,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    await _collection.add(zone.toFirestore());
  }

  /// Récupère les zones dans un rayon de 5km
  Stream<List<TacticalNoGoZone>> watchNearbyZones(GeoPoint center, {double radiusKm = 5.0}) {
    return GeoCollectionReference(_collection)
        .subscribeWithin(
          center: GeoFirePoint(center),
          radiusInKm: radiusKm,
          field: 'location',
          geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
        )
        .map((docs) => docs.map((doc) => TacticalNoGoZone.fromFirestore(doc)).toList());
  }
  
  /// Filtrage par algorithme de confiance (Shield)
  List<TacticalNoGoZone> filterTrustedZones(List<TacticalNoGoZone> zones, String currentUserId) {
    return zones.where((zone) {
      // Si trust_level >= 3, public pour tout le monde
      if (zone.trustLevel >= 3) return true;
      // Sinon, visible uniquement pour celui qui l'a rapporté
      return zone.reportedBy == currentUserId;
    }).toList();
  }
}
