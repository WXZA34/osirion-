import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../home/models/arc_data.dart';
import '../../../core/domain/entities/user_entity.dart';

class ArcRewardService {
  final Ref? ref;
  final ProviderContainer? container;

  ArcRewardService({this.ref, this.container});

  Future<void> processRewards(UserEntity user, ArcData finishedArc) async {
    final repo = ref != null 
        ? ref!.read(valerionRepositoryProvider) 
        : container!.read(valerionRepositoryProvider);

    // 1. Calculer les récompenses réelles via le repository
    final rewards = await repo.calculateArcRewards(user.id, finishedArc);

    // 2. Appliquer les récompenses
    final updatedUser = user.copyWith(
      aetherBalance: user.aetherBalance + (rewards['aether'] as int),
      xp: user.xp + (rewards['xp'] as int),
      unlockedTitles: [...user.unlockedTitles, rewards['title'] as String],
    );

    await repo.saveUserProfile(updatedUser);
    
    // Marquer l'arc comme réclamé (optionnel ici si on veut que la modal apparaisse quand même,
    // mais techniquement le service automatique "donne" les ressources sans attendre le clic)
    // Pour cet utilisateur, on va laisser la modal gérer le 'claimed' pour éviter les doublons UI,
    // mais on donne les points tout de suite pour la réactivité.
    
    debugPrint("RÉCOMPENSES AUTO DISTRIBUÉES pour ${user.username}");
  }
}

/// Provider pour accéder au service
final arcRewardServiceProvider = Provider((ref) => ArcRewardService(ref: ref));
