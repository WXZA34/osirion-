// lib/core/domain/entities/global_config_entity.dart
import 'library_audio_entity.dart';
class GlobalConfigEntity {
  final String? dailyVideoUrl;
  final String? dailyVideoTitle;
  final String? dailyVideoDescription;
  final List<LibraryAudioEntity>? forgeAudios;

  GlobalConfigEntity({
    this.dailyVideoUrl,
    this.dailyVideoTitle,
    this.dailyVideoDescription,
    this.forgeAudios,
  });

  factory GlobalConfigEntity.fromMap(Map<String, dynamic> map) {
    final url = map['dailyVideoUrl'] as String?;
    final audiosList = map['forgeAudios'] as List? ?? [];
    
    return GlobalConfigEntity(
      dailyVideoUrl: url,
      dailyVideoTitle: map['dailyVideoTitle'] as String?,
      dailyVideoDescription: map['dailyVideoDescription'] as String?,
      forgeAudios: audiosList
          .map((e) => LibraryAudioEntity.fromMap('', e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyVideoUrl': dailyVideoUrl,
      'dailyVideoTitle': dailyVideoTitle,
      'dailyVideoDescription': dailyVideoDescription,
      'forgeAudios': forgeAudios?.map((e) => e.toMap()).toList() ?? [],
    };
  }
}
