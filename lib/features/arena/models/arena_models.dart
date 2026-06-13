import '../../../core/models/lat_lng.dart';

/// Modèle pour la section "La Forge"
class ForgeConfig {
  final double distanceKm;
  final String terrainType; // "PLAT" or "VALLONNE"
  final LatLng startPosition;

  ForgeConfig({
    required this.distanceKm,
    required this.terrainType,
    required this.startPosition,
  });
}

/// Modèle pour la section "Les Territoires" (Grille Hexagonale)
class TerritoryModel {
  final String id;
  final List<LatLng> hexagonVertices;
  final String? ownerId;
  final String? ownerPseudo;
  final double currentLeaderKms;
  final DateTime lastUpdated;

  TerritoryModel({
    required this.id,
    required this.hexagonVertices,
    this.ownerId,
    this.ownerPseudo,
    this.currentLeaderKms = 0.0,
    required this.lastUpdated,
  });
}

/// Modèle pour la section "Les Bastions" (POI Street Workout)
class BastionModel {
  final String id;
  final String name;
  final LatLng position;
  final String type; // ex: "BARRES_TRACTION", "PARC_COMPLET"
  final List<BastionLeaderboardEntry> leaderboard;
  
  // Tactical Intelligence
  final List<String> equipment;
  final String? neighborhood;
  final int failedAttemptsCount;
  final DateTime? lastBeatenAt;
  final List<String> images;
  final String? osmNote;

  BastionModel({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    required this.leaderboard,
    this.equipment = const [],
    this.neighborhood,
    this.failedAttemptsCount = 0,
    this.lastBeatenAt,
    this.images = const [],
    this.osmNote,
  });

  BastionLeaderboardEntry? get currentBoss => 
    leaderboard.isEmpty ? null : leaderboard.first;

  /// Retourne le statut tactique du bastion
  String get tacticalStatus {
    if (leaderboard.isEmpty) return "VIERGE";
    
    // Si battu récemment (moins de 48h)
    if (lastBeatenAt != null && 
        DateTime.now().difference(lastBeatenAt!).inHours < 48) {
      return "CONFLIT";
    }
    
    // Si le boss règne depuis plus de 7 jours
    final achievedAt = leaderboard.first.achievedAt;
    if (DateTime.now().difference(achievedAt).inDays >= 7) {
      return "FORTERESSE";
    }
    
    return "STABLE";
  }

  /// Fusionne les données Firestore avec les données OSM
  BastionModel merge(BastionModel other) {
    return BastionModel(
      id: id,
      name: name,
      position: position,
      type: type,
      leaderboard: other.leaderboard.isNotEmpty ? other.leaderboard : leaderboard,
      equipment: equipment.isNotEmpty ? equipment : other.equipment,
      neighborhood: other.neighborhood ?? neighborhood,
      failedAttemptsCount: other.failedAttemptsCount,
      lastBeatenAt: other.lastBeatenAt ?? lastBeatenAt,
      // PRIORITÉ ABSOLUE : Donnée Firestore (Éclaireur) > OSM (fusionnée et limitée à 4)
      images: _mergeImages(images, other.images),
      osmNote: osmNote ?? other.osmNote,
    );
  }

  static List<String> _mergeImages(List<String> osmImages, List<String> firestoreImages) {
    // Si on a des images Firestore, elles sont prioritaires
    if (firestoreImages.isNotEmpty) return firestoreImages.take(4).toList();
    return osmImages.take(4).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type,
      'equipment': equipment,
      'neighborhood': neighborhood,
      'failedAttemptsCount': failedAttemptsCount,
      'lastBeatenAt': lastBeatenAt?.toIso8601String(),
      'images': images,
      'osmNote': osmNote,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  factory BastionModel.fromMap(String id, Map<String, dynamic> map, {List<BastionLeaderboardEntry> leaderboard = const []}) {
    return BastionModel(
      id: id,
      name: map['name'] ?? '',
      position: LatLng(
        (map['latitude'] ?? 0.0).toDouble(),
        (map['longitude'] ?? 0.0).toDouble(),
      ),
      type: map['type'] ?? '',
      leaderboard: leaderboard,
      equipment: List<String>.from(map['equipment'] ?? []),
      neighborhood: map['neighborhood'],
      failedAttemptsCount: map['failedAttemptsCount'] ?? 0,
      lastBeatenAt: map['lastBeatenAt'] != null 
          ? DateTime.parse(map['lastBeatenAt']) 
          : null,
      images: List<String>.from(map['images'] ?? (map['imageUrl'] != null ? [map['imageUrl']] : [])),
      osmNote: map['osmNote'],
    );
  }
}

class BastionLeaderboardEntry {
  final String userId;
  final String pseudo;
  final int reps;
  final int? dips;
  final int? pullups;
  final int? pushups;
  final int? abs;
  final String exerciseType; // "PULL_UPS", "PUSH_UPS"
  final DateTime achievedAt;

  BastionLeaderboardEntry({
    required this.userId,
    required this.pseudo,
    required this.reps,
    this.dips = 0,
    this.pullups = 0,
    this.pushups = 0,
    this.abs = 0,
    required this.exerciseType,
    required this.achievedAt,
  });

  /// Calcule le score effectif avec un déclin de 5% par semaine (0.71% par jour)
  int get effectiveReps {
    final daysPassed = DateTime.now().difference(achievedAt).inDays;
    if (daysPassed <= 0) return reps;
    
    // Déclin linéaire : 5% de perte par tranche de 7 jours
    double decayFactor = 1.0 - (daysPassed / 7.0) * 0.05;
    
    // On s'assure que le facteur ne tombe pas à 0 trop vite (minimum 50% du score original pour l'instant)
    if (decayFactor < 0.5) decayFactor = 0.5;
    
    final effective = (reps * decayFactor).round();
    return effective > 0 ? effective : 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pseudo': pseudo,
      'reps': reps,
      'dips': dips,
      'pullups': pullups,
      'pushups': pushups,
      'abs': abs,
      'exerciseType': exerciseType,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }

  factory BastionLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return BastionLeaderboardEntry(
      userId: map['userId'] ?? '',
      pseudo: map['pseudo'] ?? 'Anonyme',
      reps: map['reps'] ?? 0,
      dips: map['dips'] ?? 0,
      pullups: map['pullups'] ?? 0,
      pushups: map['pushups'] ?? 0,
      abs: map['abs'] ?? 0,
      exerciseType: map['exerciseType'] ?? 'EXERCICE',
      achievedAt: DateTime.parse(
        map['achievedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// Modèle pour la section "Le Colisée" (Ghost Run / Records Asynchrones)
class ColosseumRunModel {
  final String id;
  final String title;
  final String creatorId;
  final String creatorPseudo;
  final String activityType;
  final double distance;
  final Duration recordDuration;
  final List<LatLng> path;
  final List<double> speedProfile; // Profil de vitesse pour le Ghost
  final int challengersCount;

  ColosseumRunModel({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.creatorPseudo,
    required this.activityType,
    required this.distance,
    required this.recordDuration,
    required this.path,
    required this.speedProfile,
    this.challengersCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'creatorId': creatorId,
      'creatorPseudo': creatorPseudo,
      'activityType': activityType,
      'distance': distance,
      'recordDurationMs': recordDuration.inMilliseconds,
      'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'speedProfile': speedProfile,
      'challengersCount': challengersCount,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory ColosseumRunModel.fromMap(String id, Map<String, dynamic> map) {
    return ColosseumRunModel(
      id: id,
      title: map['title'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorPseudo: map['creatorPseudo'] ?? 'Anonyme',
      activityType: map['activityType'] ?? 'RUNNING',
      distance: (map['distance'] ?? 0.0).toDouble(),
      recordDuration: Duration(milliseconds: map['recordDurationMs'] ?? 0),
      path: (map['path'] as List<dynamic>?)
              ?.map((p) => LatLng(p['lat'], p['lng']))
              .toList() ??
          [],
      speedProfile: (map['speedProfile'] as List<dynamic>?)
              ?.map((s) => (s as num).toDouble())
              .toList() ??
          [],
      challengersCount: map['challengersCount'] ?? 0,
    );
  }
}
