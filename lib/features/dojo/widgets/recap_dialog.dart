import 'package:valerion/features/dojo/utils/dojo_translator.dart';
import 'package:valerion/l10n/app_localizations.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';

class RecapDialog extends StatelessWidget {
  final ExerciseConfig config;
  final int repCount;
  final Duration sessionDuration;
  final VoidCallback onQuit;
  final VoidCallback onReplay;

  const RecapDialog({
    super.key,
    required this.config,
    required this.repCount,
    required this.sessionDuration,
    required this.onQuit,
    required this.onReplay,
  });

  int get _xpEarned => repCount * config.defaultXpPerRep;

  String getCoachMessage(BuildContext context) {
    if (repCount == 0) return DojoTranslator.translate(context, "Commence par te placer devant la caméra. L'IA veille sur toi !");
    if (repCount < 5) return DojoTranslator.translate(context, "Bon début ! La régularité forge les champions.");
    if (repCount < 15) return DojoTranslator.translate(context, "Solide. Tu construis une base en béton armé. 💪");
    if (repCount < 30) return DojoTranslator.translate(context, "Impressionnant ! Ton moteur tourne à plein régime. 🔥");
    return DojoTranslator.translate(context, "LÉGENDAIRE ! Tu repousses tes limites à chaque session. 🏆");
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0C10),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Titre
          Text(AppLocalizations.of(context)!.dojoRapportDeMission,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DojoTranslator.translate(context, config.name).toUpperCase(),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                icon: Icons.repeat,
                value: repCount.toString(),
                label: config.unit == 'seconds' ? DojoTranslator.translate(context, 'SECONDES') : AppLocalizations.of(context)!.dojoRPTitions,
                color: Colors.cyanAccent,
              ),
              Container(width: 1, height: 50, color: Colors.white10),
              _buildStat(
                icon: Icons.timer,
                value: _formatDuration(sessionDuration),
                label: AppLocalizations.of(context)!.dojoDurE,
                color: Colors.white,
              ),
              Container(width: 1, height: 50, color: Colors.white10),
              _buildStat(
                icon: Icons.bolt,
                value: '+$_xpEarned',
                label: AppLocalizations.of(context)!.dojoXpGagnS,
                color: Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Message coaching
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.dojoEmptyKey, style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getCoachMessage(context),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay, size: 18),
                  label: Text(AppLocalizations.of(context)!.commonReplay),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onQuit,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(AppLocalizations.of(context)!.commonFinish),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
