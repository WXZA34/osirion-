import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/models/arc_data.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import '../../features/rewards/arc_reward_service.dart';
import '../../core/services/notification_service.dart';

/// Un provider qui émet l'heure actuelle chaque minute (ou plus souvent pour les tests)
final timeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 60), (_) => DateTime.now())
      .asBroadcastStream();
});

/// Le provider central de l'Arc actuel. 
/// Il priorise le choix manuel de l'utilisateur dans son profil, 
/// sinon il recalcule l'ArcData selon la date actuelle.
final arcProvider = Provider<ArcData>((ref) {
  // 1. Check le profil utilisateur
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user?.activeArcId != null) {
    // On cherche l'arc par son ID/Titre
    if (user!.activeArcId == "SUMMER BODY") {
      return ArcData.getSummerArc(); // On assumera qu'on ajoute ces helpers ou on cherche par mois test
    } else if (user.activeArcId == "ROYAL ARC") {
      return ArcData.getRoyalArc();
    } else if (user.activeArcId == "WINTER ARC") {
      return ArcData.getWinterArc();
    }
  }

  // 2. Sinon, Fallback sur la date système
  final timeAsync = ref.watch(timeProvider);
  final now = timeAsync.value ?? DateTime.now();
  
  return ArcData.getCurrentArc(now);
});

/// Provider qui stocke l'Arc qui vient de se terminer pour afficher la modal globalement
final pendingArcRewardProvider = StateProvider<ArcData?>((ref) => null);

/// Utility provider pour savoir si on est en été sans regarder tout l'objet
final isSummerProvider = Provider<bool>((ref) {
  return ref.watch(arcProvider).arcType == AlphaArc.summer;
});

/// Service qui surveille les changements d'Arc pour déclencher les récompenses et les notifications
final arcTransitionProvider = Provider<void>((ref) {
  // SOUSCRIPTION INITIALE : S'assurer que l'abonnement est actif au démarrage
  final currentArc = ref.read(arcProvider);
  NotificationService.subscribeToArc(currentArc.title);

  ref.listen<ArcData>(arcProvider, (previous, next) {
    if (previous == null || previous.arcType != next.arcType) {
      // Un nouvel Arc commence ou c'est l'initialisation !
      final user = ref.read(userProfileProvider).valueOrNull;
      
      // 1. Gérer les récompenses de fin d'Arc (si transition réelle)
      if (previous != null && user != null) {
        ref.read(arcRewardServiceProvider).processRewards(user, previous);
        ref.read(pendingArcRewardProvider.notifier).state = previous;
      }

      // 2. Mettre à jour les abonnements aux Notifications FCM
      if (previous != null) {
        NotificationService.unsubscribeFromArc(previous.title);
      }
      NotificationService.subscribeToArc(next.title);
      
      debugPrint("TRANSITION D'ARC : ${previous?.title ?? 'INIT'} -> ${next.title}");
    }
  });
});
