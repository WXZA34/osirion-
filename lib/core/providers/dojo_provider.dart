import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dojo/models/exercise_config.dart';
import 'repository_providers.dart';

/// Provider qui expose la liste des exercices du Dojo depuis Firestore en temps réel.
final dojoExercisesProvider = StreamProvider<List<ExerciseConfig>>((ref) {
  final repository = ref.watch(valerionRepositoryProvider);

  // Écoute pure de Firestore sans auto-migration
  return repository.getDojoExercises().handleError((error) {
    debugPrint("❌ [DojoProvider] Erreur : $error");
  }).map((list) {
    // On retourne la liste filtrée (on enlève les documents techniques potentiels)
    return list.where((e) => !e.id.startsWith('_')).toList();
  });
});

/// Provider utilitaire pour filtrer les exercices par cible et par type de manière réactive.
final filteredExercisesProvider = Provider.family<List<ExerciseConfig>, ({String target, String type})>((ref, arg) {
  final exercisesAsync = ref.watch(dojoExercisesProvider);
  
  return exercisesAsync.when(
    data: (list) {
      return list.where((e) => e.targetBodyPart == arg.target && e.trainingType == arg.type).toList();
    },
    loading: () => [], // Pas de fallback, source de vérité = Firestore
    error: (_, __) => [], 
  );
});
