import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_service.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref);
  // Auto-start listening
  ref.listen<AsyncValue<bool>>(networkServiceProvider, (previous, next) {
    if (next.value == true) {
      manager.syncPendingTasks();
    }
  });
  return manager;
});

class SyncManager {
  SyncManager(Ref ref);

  Future<void> syncPendingTasks() async {
    // Désactivé : OfflineQueueService a été supprimé.
    // L'implémentation de la file d'attente hors-ligne devra être refaite.
  }
}
