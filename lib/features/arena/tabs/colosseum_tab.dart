import 'package:valerion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/arena_models.dart';
import '../arena_active_screen.dart';
import '../../../core/providers/arc_provider.dart';
import '../../home/models/arc_data.dart';

class ColosseumTab extends ConsumerStatefulWidget {
  const ColosseumTab({super.key});

  @override
  ConsumerState<ColosseumTab> createState() => _ColosseumTabState();
}

class _ColosseumTabState extends ConsumerState<ColosseumTab> {
  String _selectedSport = 'RUNNING';

  @override
  Widget build(BuildContext context) {
    final runsStream = ref.watch(colosseumRunsProvider);
    final arc = ref.watch(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;

    return Column(
      children: [
        _buildSportSelector(arc, isSummer),
        Expanded(
          child: runsStream.when(
            data: (allRuns) {
              final runs = allRuns.where((r) => r.activityType == _selectedSport).toList();
              return runs.isEmpty
                  ? _buildEmptyState(context, ref)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: runs.length,
                      itemBuilder: (context, index) => _buildChallengeCard(context, ref, runs[index]),
                    );
            },
            loading: () => Center(child: CircularProgressIndicator(color: arc.primaryColor)),
            error: (e, s) => Center(child: Text("Erreur : $e", style: const TextStyle(color: Colors.redAccent))),
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelector(ArcData arc, bool isSummer) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
      ),
      child: Row(
        children: [
          _buildSportTab('RUNNING', AppLocalizations.of(context)!.commonCourse.toUpperCase(), Icons.directions_run, arc, isSummer),
          _buildSportTab('WALKING', AppLocalizations.of(context)!.commonMarche.toUpperCase(), Icons.directions_walk, arc, isSummer),
          _buildSportTab('CYCLING', AppLocalizations.of(context)!.commonVelo.toUpperCase(), Icons.directions_bike, arc, isSummer),
        ],
      ),
    );
  }

  Widget _buildSportTab(String type, String label, IconData icon, ArcData arc, bool isSummer) {
    final isSelected = _selectedSport == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSport = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? arc.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: arc.primaryColor.withValues(alpha: 0.5)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? arc.primaryColor : (isSummer ? Colors.black38 : Colors.white30),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? arc.primaryColor : (isSummer ? Colors.black38 : Colors.white30),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;

    String sportName = "COURSE";
    if (_selectedSport == 'WALKING') sportName = "MARCHE";
    if (_selectedSport == 'CYCLING') sportName = "VÉLO";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.1) : Colors.white24),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.arenaAucunTraceDeGrave(sportName),
            style: TextStyle(
              color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.arenaSoyezLePremierGraver,
            style: TextStyle(
              color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.2) : Colors.white24,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, WidgetRef ref, ColosseumRunModel run) {
    final arc = ref.watch(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: arc.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
        boxShadow: [
          if (isSummer)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showStartChallengeDialog(context, ref, run),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          run.title.toLowerCase().startsWith('parcours de ') 
                              ? (AppLocalizations.of(context)!.arenaParcoursDePrefix + run.title.substring(12)).toUpperCase()
                              : run.title.toUpperCase(),
                          style: TextStyle(
                            color: isSummer ? arc.onSurfaceColor : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: arc.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${run.distance.toStringAsFixed(1)} KM",
                          style: TextStyle(
                            color: arc.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.arenaParPrefix + run.creatorPseudo.toUpperCase(),
                        style: TextStyle(
                          color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.timer, size: 14, color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(run.recordDuration),
                        style: TextStyle(
                          color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: arc.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.arenaMatchmakingGlobalAlphaDisponible,
                        style: TextStyle(
                          color: arc.primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStartChallengeDialog(BuildContext context, WidgetRef ref, ColosseumRunModel run) {
    final arc = ref.read(arcProvider);
    final isSummer = arc.arcType == AlphaArc.summer;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: arc.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: arc.primaryColor, width: 2),
        ),
        title: Text(
          AppLocalizations.of(context)!.arenaDefierPrefix + run.creatorPseudo.toUpperCase(),
          style: TextStyle(
            color: isSummer ? arc.onSurfaceColor : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.arenaModeMatchmakingRelatifGlobal,
              style: TextStyle(color: arc.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.arenaVousAllezAffronterLe,
              style: TextStyle(
                color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.7) : Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(arc, AppLocalizations.of(context)!.commonDistanceTitle, "${run.distance} km"),
            _buildStatRow(arc, AppLocalizations.of(context)!.commonRecordTitle, _formatDuration(run.recordDuration)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.commonCancel,
              style: TextStyle(color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white24),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Incrémenter atomique du nombre de challengers via Cloud Function (Sécurité)
      await ref
          .read(valerionRepositoryProvider)
          .joinColosseumRun(runId: run.id);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArenaActiveScreen(
                    sportType: run.activityType,
                    targetDistanceKm: run.distance,
                    ghostTarget: run,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: arc.primaryColor,
              foregroundColor: isSummer ? Colors.white : Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(AppLocalizations.of(context)!.arenaLancerLeDuel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(ArcData arc, String label, String value) {
    final isSummer = arc.arcType == AlphaArc.summer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSummer ? arc.onSurfaceColor : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String m = d.inMinutes.toString().padLeft(2, '0');
    String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

final colosseumRunsProvider = StreamProvider<List<ColosseumRunModel>>((ref) {
  return ref.watch(valerionRepositoryProvider).listenColosseumRuns();
});
