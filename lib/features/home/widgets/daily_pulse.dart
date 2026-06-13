import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_pulse_provider.dart';
import '../models/arc_data.dart';
import 'package:valerion/core/providers/arc_provider.dart';

class DailyPulse extends ConsumerWidget {
  final Color themeColor;

  const DailyPulse({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(dailyPulseProvider);

    final arc = ref.watch(arcProvider);
    final bool isSummer = arc.arcType == AlphaArc.summer;

    if (quests.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: isSummer ? Colors.white : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSummer ? Colors.black12 : themeColor.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: CircularProgressIndicator(color: isSummer ? themeColor : Colors.cyan),
        ),
      );
    }

    int completedTasks = quests.where((t) => t.isDone == true).length;
    int totalTasks = quests.length;
    double progress = totalTasks > 0 ? completedTasks / totalTasks : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isSummer ? Colors.white : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isSummer ? Colors.black12 : themeColor.withValues(alpha: 0.2)),
        boxShadow: [
          if (isSummer)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PULSE QUOTIDIEN",
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withValues(
                    alpha:
                        completedTasks == totalTasks && totalTasks > 0
                            ? 1
                            : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$completedTasks / $totalTasks",
                  style: TextStyle(
                    color:
                        completedTasks == totalTasks && totalTasks > 0
                            ? Colors.black
                            : themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (progress > 0)
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Liste des tâches
          ...quests.asMap().entries.map((entry) {
            final index = entry.key;
            final quest = entry.value;
            return _buildTaskItem(quest, index, ref, isSummer);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Quest quest, int index, WidgetRef ref, bool isSummer) {
    bool isDone = quest.isDone;
    return GestureDetector(
      onTap: () {
        ref.read(dailyPulseProvider.notifier).toggleQuestState(index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDone ? themeColor.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone 
                ? themeColor.withValues(alpha: 0.3) 
                : (isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
          ),
        ),
        child: Row(
          children: [
            Icon(
              quest.icon,
              color: isDone ? themeColor : (isSummer ? Colors.black12 : Colors.white24),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                      color: isDone 
                          ? (isSummer ? Colors.black54 : Colors.white70) 
                          : (isSummer ? Colors.black26 : Colors.white38),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.desc,
                    style: TextStyle(
                      color: isDone 
                          ? (isSummer ? Colors.black87 : Colors.white) 
                          : (isSummer ? Colors.black54 : Colors.white70),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox custom
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? themeColor : Colors.transparent,
                border: Border.all(
                  color: isDone ? themeColor : (isSummer ? Colors.black12 : Colors.white24),
                  width: 2,
                ),
              ),
              child:
                  isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
