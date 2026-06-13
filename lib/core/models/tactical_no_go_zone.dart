import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class TacticalNoGoZone {
  final String id;
  final GeoFirePoint location;
  final String reportedBy;
  final int trustLevel;
  final DateTime expiresAt;

  TacticalNoGoZone({
    required this.id,
    required this.location,
    required this.reportedBy,
    required this.trustLevel,
    required this.expiresAt,
  });

  factory TacticalNoGoZone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint geopoint = data['location']['geopoint'];


    return TacticalNoGoZone(
      id: doc.id,
      location: GeoFirePoint(geopoint),
      reportedBy: data['reported_by'] ?? '',
      trustLevel: data['trust_level'] ?? 1,
      expiresAt: (data['expires_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'location': {
        'geopoint': location.geopoint,
        'geohash': location.geohash,
      },
      'reported_by': reportedBy,
      'trust_level': trustLevel,
      'expires_at': Timestamp.fromDate(expiresAt),
    };
  }
}
