import 'package:cloud_firestore/cloud_firestore.dart';

// lib/core/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String username;
  final String email;
  final int level;
  final int xp;
  final List<String> clanIds;
  final DateTime createdAt;

  // Nouveaux champs avancés
  final int? age;
  final int? height; // en cm
  final double? weight;
  final double? bodyFat;
  final double? muscleMass;
  final int forceXp;
  final int wisdomXp;
  final int maxPushups;
  final int maxPullups;
  final int streak;
  final DateTime? lastActiveDate;
  final DateTime? lastReadSystemTimestamp;
  final String? profileImageUrl;
  final List<String> friendIds;
  final List<String> incomingRequestIds;
  final List<String> outgoingRequestIds;
  final String? status;
  final String? usernameLower;
  final List<String> inventory;

  // Économie et Cosmétiques
  final int aetherBalance;
  final int gold;
  final String? activeHalo;
  final String? activeTitle;
  final List<String> unlockedTitles;

  // Setup Flow
  final String? guardianPath;
  final String? ultimateOath;

  // Champs de Performance
  final double? movementPrecision;
  final double? bestPace1km;
  final double? bestAlphaLoop6km;
  final double? totalDistance;
  final String? activeArcId;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.level,
    required this.xp,
    this.clanIds = const <String>[],
    required this.createdAt,
    this.age,
    this.height,
    this.weight,
    this.bodyFat,
    this.muscleMass,
    this.forceXp = 0,
    this.wisdomXp = 0,
    this.maxPushups = 0,
    this.maxPullups = 0,
    this.streak = 0,
    this.lastActiveDate,
    this.lastReadSystemTimestamp,
    this.profileImageUrl,
    this.friendIds = const <String>[],
    this.incomingRequestIds = const <String>[],
    this.outgoingRequestIds = const <String>[],
    this.status = "online",
    this.usernameLower,
    this.movementPrecision = 0.0,
    this.bestPace1km = 0.0,
    this.bestAlphaLoop6km = 0.0,
    this.totalDistance = 0.0,
    this.inventory = const <String>[],
    this.aetherBalance = 0,
    this.gold = 0,
    this.activeHalo,
    this.activeTitle,
    this.unlockedTitles = const <String>[],
    this.activeArcId,
    this.guardianPath,
    this.ultimateOath,
  });

  // Copie de l'objet avec de nouvelles valeurs (utile pour les mises à jour en mémoire)
  UserEntity copyWith({
    String? id,
    String? username,
    String? email,
    int? level,
    int? xp,
    List<String>? clanIds,
    DateTime? createdAt,
    int? age,
    int? height,
    double? weight,
    double? bodyFat,
    double? muscleMass,
    int? forceXp,
    int? wisdomXp,
    int? maxPushups,
    int? maxPullups,
    int? streak,
    DateTime? lastActiveDate,
    DateTime? lastReadSystemTimestamp,
    String? profileImageUrl,
    List<String>? friendIds,
    List<String>? incomingRequestIds,
    List<String>? outgoingRequestIds,
    String? status,
    String? usernameLower,
    double? movementPrecision,
    double? bestPace1km,
    double? bestAlphaLoop6km,
    double? totalDistance,
    List<String>? inventory,
    int? aetherBalance,
    int? gold,
    String? activeHalo,
    String? activeTitle,
    List<String>? unlockedTitles,
    String? activeArcId,
    String? guardianPath,
    String? ultimateOath,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      clanIds: clanIds ?? this.clanIds,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      forceXp: forceXp ?? this.forceXp,
      wisdomXp: wisdomXp ?? this.wisdomXp,
      maxPushups: maxPushups ?? this.maxPushups,
      maxPullups: maxPullups ?? this.maxPullups,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastReadSystemTimestamp: lastReadSystemTimestamp ?? this.lastReadSystemTimestamp,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      friendIds: friendIds ?? this.friendIds,
      incomingRequestIds: incomingRequestIds ?? this.incomingRequestIds,
      outgoingRequestIds: outgoingRequestIds ?? this.outgoingRequestIds,
      status: status ?? this.status,
      usernameLower: usernameLower ?? this.usernameLower,
      movementPrecision: movementPrecision ?? this.movementPrecision,
      bestPace1km: bestPace1km ?? this.bestPace1km,
      bestAlphaLoop6km: bestAlphaLoop6km ?? this.bestAlphaLoop6km,
      totalDistance: totalDistance ?? this.totalDistance,
      inventory: inventory ?? this.inventory,
      aetherBalance: aetherBalance ?? this.aetherBalance,
      gold: gold ?? this.gold,
      activeHalo: activeHalo ?? this.activeHalo,
      activeTitle: activeTitle ?? this.activeTitle,
      unlockedTitles: unlockedTitles ?? this.unlockedTitles,
      activeArcId: activeArcId ?? this.activeArcId,
      guardianPath: guardianPath ?? this.guardianPath,
      ultimateOath: ultimateOath ?? this.ultimateOath,
    );
  }

  static UserEntity fromMap(String id, Map<String, dynamic> data) {
    // Helper pour extraire les entiers de manière sécurisée (Firestore peut renvoyer des doubles)
    int toInt(dynamic val, int defaultValue) {
      if (val == null) return defaultValue;
      if (val is int) return val;
      if (val is double) return val.toInt();
      return defaultValue;
    }

    // Helper pour extraire les doubles
    double toDouble(dynamic val, double defaultValue) {
      if (val == null) return defaultValue;
      if (val is num) return val.toDouble();
      return defaultValue;
    }

    DateTime? toDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserEntity(
      id: id,
      username: data['username'] as String? ?? 'Alpha',
      email: data['email'] as String? ?? '',
      level: toInt(data['level'], 1),
      xp: toInt(data['xp'], 0),
      clanIds: List<String>.from(data['clanIds'] ?? []),
      createdAt: toDate(data['createdAt']) ?? DateTime.now(),
      age: data['age'] as int?,
      height: data['height'] as int?,
      weight: toDouble(data['weight'], 0.0),
      bodyFat: toDouble(data['bodyFat'], 0.0),
      muscleMass: toDouble(data['muscleMass'], 0.0),
      forceXp: toInt(data['forceXp'], 0),
      wisdomXp: toInt(data['wisdomXp'], 0),
      maxPushups: toInt(data['maxPushups'], 0),
      maxPullups: toInt(data['maxPullups'], 0),
      streak: toInt(data['streak'], 0),
      lastActiveDate: toDate(data['lastActiveDate']),
      lastReadSystemTimestamp: toDate(data['lastReadSystemTimestamp']),
      profileImageUrl: data['profileImageUrl'] as String?,
      friendIds: List<String>.from(data['friendIds'] ?? []),
      incomingRequestIds: List<String>.from(data['incomingRequestIds'] ?? []),
      outgoingRequestIds: List<String>.from(data['outgoingRequestIds'] ?? []),
      status: data['status'] as String? ?? "online",
      usernameLower: data['usernameLower'] as String?,
      movementPrecision: toDouble(data['movementPrecision'], 0.0),
      bestPace1km: toDouble(data['bestPace1km'], 0.0),
      bestAlphaLoop6km: toDouble(data['bestAlphaLoop6km'], 0.0),
      totalDistance: toDouble(data['totalDistance'], 0.0),
      inventory: List<String>.from(data['inventory'] ?? []),
      aetherBalance: toInt(data['aetherBalance'], 0),
      gold: toInt(data['gold'], 0),
      activeHalo: data['activeHalo'] as String?,
      activeTitle: data['activeTitle'] as String?,
      unlockedTitles: List<String>.from(data['unlockedTitles'] ?? []),
      activeArcId: data['activeArcId'] as String?,
      guardianPath: data['guardianPath'] as String?,
      ultimateOath: data['ultimateOath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'username': username,
      'email': email,
      'level': level,
      'xp': xp,
      'createdAt': Timestamp.fromDate(createdAt),
      'forceXp': forceXp,
      'wisdomXp': wisdomXp,
      'maxPushups': maxPushups,
      'maxPullups': maxPullups,
      'streak': streak,
      'status': status,
      'usernameLower': usernameLower ?? username.toLowerCase(),
      'movementPrecision': movementPrecision,
      'bestPace1km': bestPace1km,
      'bestAlphaLoop6km': bestAlphaLoop6km,
      'totalDistance': totalDistance,
      'inventory': inventory,
      'friendIds': friendIds,
      'incomingRequestIds': incomingRequestIds,
      'outgoingRequestIds': outgoingRequestIds,
      'clanIds': clanIds, // RÉINCORPORATION DU CHAMP MANQUANT
      'aetherBalance': aetherBalance,
      'gold': gold,
      'unlockedTitles': unlockedTitles,
    };

    // Ajout conditionnel des champs optionnels non-nuls
    if (age != null) map['age'] = age;
    if (height != null) map['height'] = height;
    if (weight != null) map['weight'] = weight;
    if (bodyFat != null) map['bodyFat'] = bodyFat;
    if (muscleMass != null) map['muscleMass'] = muscleMass;
    if (lastActiveDate != null) map['lastActiveDate'] = Timestamp.fromDate(lastActiveDate!);
    if (lastReadSystemTimestamp != null) map['lastReadSystemTimestamp'] = Timestamp.fromDate(lastReadSystemTimestamp!);
    if (profileImageUrl != null) map['profileImageUrl'] = profileImageUrl;
    map['activeHalo'] = activeHalo;
    map['activeTitle'] = activeTitle;
    if (activeArcId != null) map['activeArcId'] = activeArcId;
    if (guardianPath != null) map['guardianPath'] = guardianPath;
    if (ultimateOath != null) map['ultimateOath'] = ultimateOath;

    return map;
  }
}
