// lib/core/domain/entities/clan_request_entity.dart

enum ClanRequestType { invitation, request }

enum ClanRequestStatus { pending, accepted, rejected }

class ClanRequestEntity {
  final String id;
  final String clanId;
  final String
  clanName; // Utile pour afficher le nom du clan dans les invitations
  final String userId;
  final String username; // Utile pour afficher le nom du demandeur
  final ClanRequestType type;
  final ClanRequestStatus status;
  final DateTime createdAt;

  ClanRequestEntity({
    required this.id,
    required this.clanId,
    required this.clanName,
    required this.userId,
    required this.username,
    required this.type,
    this.status = ClanRequestStatus.pending,
    required this.createdAt,
  });

  ClanRequestEntity copyWith({
    String? id,
    String? clanId,
    String? clanName,
    String? userId,
    String? username,
    ClanRequestType? type,
    ClanRequestStatus? status,
    DateTime? createdAt,
  }) {
    return ClanRequestEntity(
      id: id ?? this.id,
      clanId: clanId ?? this.clanId,
      clanName: clanName ?? this.clanName,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
