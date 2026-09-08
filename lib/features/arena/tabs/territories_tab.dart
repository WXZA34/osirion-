import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/models/arc_data.dart';
import '../../../core/providers/arc_provider.dart';

class TerritoriesTab extends ConsumerWidget {
  const TerritoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_4x4, size: 80, color: arc.primaryColor.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.arenaLesTerritoires,
            style: TextStyle(
              color: isSummer ? arc.onSurfaceColor : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context)!.arenaConquTesGOlocalis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.6) : Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: arc.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: arc.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              AppLocalizations.of(context)!.arenaDVeloppementEnCours,
              style: TextStyle(color: arc.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
