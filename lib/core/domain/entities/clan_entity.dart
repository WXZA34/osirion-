// lib/core/domain/entities/clan_entity.dart
class ClanEntity {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final int membersCount;
  final int totalXp;
  final DateTime createdAt;
  final String? logoUrl;
  final Map<String, int> unreadCounts;

  ClanEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.membersCount,
    required this.totalXp,
    required this.createdAt,
    this.logoUrl,
    this.unreadCounts = const <String, int>{},
  });

  ClanEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? leaderId,
    int? membersCount,
    int? totalXp,
    DateTime? createdAt,
    String? logoUrl,
    Map<String, int>? unreadCounts,
  }) {
    return ClanEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId ?? this.leaderId,
      membersCount: membersCount ?? this.membersCount,
      totalXp: totalXp ?? this.totalXp,
      createdAt: createdAt ?? this.createdAt,
      logoUrl: logoUrl ?? this.logoUrl,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }
}
