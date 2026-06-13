import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dojo/models/exercise_config.dart';
import 'repository_providers.dart';

/// Provider qui expose la liste des exercices du Dojo depuis Firestore en temps réel.
final dojoExercisesProvider = StreamProvider<List<ExerciseConfig>>((ref) {
  final repository = ref.watch(valerionRepositoryProvider);

  // Auto-initialisation : On écoute le flux
  return repository.getDojoExercises().handleError((error) {
    debugPrint("❌ [DojoProvider] Erreur : $error");
  }).map((list) {
    // Vérifier si le document sentinelle existe
    final migrationDone = list.any((e) => e.id == '_migration_done');
    
    // Si la sentinelle est absente, on déclenche l'upload des données par défaut
    if (!migrationDone) {
      debugPrint("🚀 [DojoProvider] Migration manquante ou Firestore vide, initialisation...");
      repository.uploadDefaultExercises(ValerionExercises.catalogue);
    }
    
    // On retourne la liste filtrée (on enlève les documents techniques comme la sentinelle)
    return list.where((e) => !e.id.startsWith('_')).toList();
  });
});

/// Provider utilitaire pour filtrer les exercices par cible et par type de manière réactive.
final filteredExercisesProvider = Provider.family<List<ExerciseConfig>, ({String target, String type})>((ref, arg) {
  final exercisesAsync = ref.watch(dojoExercisesProvider);
  
  return exercisesAsync.when(
    data: (list) {
      final filtered = list.where((e) => e.targetBodyPart == arg.target && e.trainingType == arg.type).toList();
      
      // Fallback sur le catalogue statique si Firestore est vide (première migration)
      if (filtered.isEmpty) {
        return ValerionExercises.getByTargetAndType(arg.target, arg.type);
      }
      
      return filtered;
    },
    loading: () => ValerionExercises.getByTargetAndType(arg.target, arg.type), // Fallback pendant le chargement
    error: (_, __) => ValerionExercises.getByTargetAndType(arg.target, arg.type), // Fallback en cas d'erreur
  );
});
