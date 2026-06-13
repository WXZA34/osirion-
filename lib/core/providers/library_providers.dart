import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/library/models/book_entity.dart';
import '../domain/entities/library_audio_entity.dart';
import 'repository_providers.dart';
import '../../features/arsenal/models/relic.dart';
import 'package:flutter/foundation.dart';

/// Provider pour les livres de la bibliothèque (Stream Firestore)
final libraryBooksProvider = StreamProvider<List<BookEntity>>((ref) {
  final repository = ref.watch(valerionRepositoryProvider);

  return repository.listenLibraryBooks().handleError((error) {
    debugPrint("❌ [LibraryBooksProvider] Erreur : $error");
  }).map((list) {
    return list.where((b) => !b.id.startsWith('_')).toList();
  });
});

/// Provider pour les audios de la bibliothèque (Stream Firestore)
final libraryAudiosProvider = StreamProvider<List<LibraryAudioEntity>>((ref) {
  final repository = ref.watch(valerionRepositoryProvider);

  return repository.listenLibraryAudios().handleError((error) {
    debugPrint("❌ [LibraryAudiosProvider] Erreur : $error");
  }).map((list) {
    return list.where((a) => !a.id.startsWith('_')).toList();
  });
});

/// Provider pour les reliques de l'Arsenal (Stream Firestore)
final relicsProvider = StreamProvider<List<Relic>>((ref) {
  final repository = ref.watch(valerionRepositoryProvider);

  return repository.listenArsenalRelics().handleError((error) {
    debugPrint("❌ [RelicsProvider] Erreur : $error");
  }).map((list) {
    return list.where((r) => !r.id.startsWith('_')).toList();
  });
});
