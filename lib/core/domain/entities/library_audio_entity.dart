import 'package:equatable/equatable.dart';

class LibraryAudioEntity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String audioUrl;
  final String iconName;
  final String category; // 'forge', 'recovery', 'motivation', etc.
  final int order;
  final bool isAsset;

  const LibraryAudioEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.audioUrl,
    this.iconName = 'music_note',
    this.category = 'forge',
    this.order = 0,
    this.isAsset = false,
  });

  factory LibraryAudioEntity.fromMap(String id, Map<String, dynamic> map) {
    return LibraryAudioEntity(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      iconName: map['iconName'] ?? 'music_note',
      category: map['category'] ?? 'forge',
      order: map['order'] ?? 0,
      isAsset: map['isAsset'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'audioUrl': audioUrl,
      'iconName': iconName,
      'category': category,
      'order': order,
      'isAsset': isAsset,
    };
  }

  @override
  List<Object?> get props => [id, title, subtitle, audioUrl, iconName, category, order, isAsset];
}

class ValerionAudios {
  static const List<LibraryAudioEntity> catalogue = [
    LibraryAudioEntity(
      id: 'static_1',
      title: "3 Minutes Pour Transformer Ta Vie",
      subtitle: "3 min • Motivation",
      audioUrl: "audio/transformer_vie.m4a",
      iconName: 'flash_on',
      isAsset: true,
      order: 1,
    ),
    LibraryAudioEntity(
      id: 'static_2',
      title: "Si Tu Procrastines, Écoute Ça",
      subtitle: "Motivation • Focus",
      audioUrl: "audio/anti_procrastination.m4a",
      iconName: 'av_timer',
      isAsset: true,
      order: 2,
    ),
    LibraryAudioEntity(
      id: 'static_saitama',
      title: "Le Discours de Saitama",
      subtitle: "Détermination • Alpha",
      audioUrl: "audio/saitama_discours.m4a",
      iconName: 'sports_martial_arts',
      isAsset: true,
      order: 3,
    ),
    LibraryAudioEntity(
      id: 'static_reveiller',
      title: "Réveiller quelque chose en toi",
      subtitle: "David Goggins • Interview",
      audioUrl: "audio/CETTE INTERVIEW VA REVEILLER QUELQUE CHOSE EN TOI ! David Goggins.m4a",
      iconName: 'campaign',
      isAsset: true,
      order: 4,
    ),
    LibraryAudioEntity(
      id: 'static_3',
      title: "Ton Seul Obstacle, C’est TOI",
      subtitle: "Mindset Alpha",
      audioUrl:
          "https://firebasestorage.googleapis.com/v0/b/valerion-55414.firebasestorage.app/o/Ton%20Seul%20Obstacle%2C%20C%E2%80%99est%20TOI%20!.m4a?alt=media&token=7550d002-c27a-4560-9d24-5c657316e9ac",
      iconName: 'looks_one',
      order: 5,
    ),
    LibraryAudioEntity(
      id: 'static_4',
      title: "L'Art de Maîtriser Son Esprit",
      subtitle: "David Goggins • Interview",
      audioUrl:
          "https://firebasestorage.googleapis.com/v0/b/valerion-55414.firebasestorage.app/o/L'ART%20DE%20MA%C3%8ETRISER%20SON%20ESPRIT%20POUR%20R%C3%89USSIR%20SA%20VIE%20%20David%20Goggins.m4a?alt=media&token=6f8df443-36e5-46be-ae74-e78d5b1e450d",
      iconName: 'self_improvement',
      order: 6,
    ),
  ];
}
