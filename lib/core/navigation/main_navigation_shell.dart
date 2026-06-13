import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/features/home/home_screen.dart';
import 'package:valerion/features/home/widgets/arc_completion_dialog.dart';
import 'package:valerion/core/providers/arc_provider.dart';
import 'package:valerion/core/providers/repository_providers.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  @override
  Widget build(BuildContext context) {
    // Activer les services de transition (Récompenses & Notifications)
    ref.watch(arcTransitionProvider);

    // Écouteur global pour les récompenses d'Arc
    ref.listen(pendingArcRewardProvider, (previous, next) {
      if (next != null) {
        final user = ref.read(userProfileProvider).valueOrNull;
        if (user != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ArcCompletionDialog(arc: next, user: user),
          ).then((_) {
            // Une fois la modal fermée, on reset le provider
            ref.read(pendingArcRewardProvider.notifier).state = null;
          });
        }
      }
    });

    return const Scaffold(
      body: HomeScreen(), // La navigation gère désormais tout en interne
    );
  }
}
