// lib/core/domain/entities/clan_message_entity.dart

class ClanMessageEntity {
  final String id;
  final String clanId;
  final String senderId;
  final String senderName;
  final String? text;
  final String? audioUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String type; // 'text', 'audio', 'image', 'video'
  final DateTime timestamp;
  final bool isOptimistic;

  ClanMessageEntity({
    required this.id,
    required this.clanId,
    required this.senderId,
    required this.senderName,
    this.text,
    this.audioUrl,
    this.imageUrl,
    this.videoUrl,
    this.type = 'text',
    required this.timestamp,
    this.isOptimistic = false,
  });

  ClanMessageEntity copyWith({
    String? id,
    String? clanId,
    String? senderId,
    String? senderName,
    String? text,
    String? audioUrl,
    String? imageUrl,
    String? videoUrl,
    String? type,
    DateTime? timestamp,
    bool? isOptimistic,
  }) {
    return ClanMessageEntity(
      id: id ?? this.id,
      clanId: clanId ?? this.clanId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}
