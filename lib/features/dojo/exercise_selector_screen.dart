import 'package:flutter/material.dart';
import '../home/models/arc_data.dart';
import 'models/exercise_config.dart';
import 'exercise_demo_screen.dart';
import 'guided_workout_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/dojo_provider.dart';

class ExerciseSelectorScreen extends ConsumerWidget {
  final String targetBodyPart;
  final String trainingType;
  final String mode;

  const ExerciseSelectorScreen({
    super.key,
    required this.targetBodyPart,
    required this.trainingType,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExercises = ref.watch(filteredExercisesProvider((
      target: targetBodyPart,
      type: trainingType,
    )));

    // Filtrage dynamique : En mode VISION, on ne garde que les exos supportés par l'IA
    final exercises = mode == 'VISION' 
        ? allExercises.where((e) => e.hasAiSupport).toList()
        : allExercises;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "SÉLECTION DE L'EXERCICE",
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          exercises.isEmpty
              ? const Center(
                child: Text(
                  "Aucun protocole disponible pour cette configuration.",
                  style: TextStyle(color: Colors.white54),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final config = exercises[index];
                  return _buildExerciseCard(context, ref, config);
                },
              ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WidgetRef ref, ExerciseConfig config) {
    final bool isSummer = ArcData.getCurrentArc().arcType == AlphaArc.summer;
    return Card(
      color: isSummer ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F172A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSummer ? Colors.black12 : Colors.white10),
      ),
      elevation: 8,
      child: InkWell(
        onTap: () {
          if (mode == 'GUIDE') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GuidedWorkoutScreen(config: config),
              ),
            );
          } else {
            // Mode VISION : Démo avant l'exercice
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDemoScreen(config: config),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Expanded(
                      child: Text(
                        config.name.toUpperCase(),
                        style: TextStyle(
                          color: isSummer ? Colors.black : Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isSummer ? Colors.black26 : Colors.white24,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                config.description,
                style: TextStyle(color: isSummer ? Colors.black87 : Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "+${config.defaultXpPerRep} XP / ${config.unit == 'seconds' ? 'Sec' : 'Rep'}",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
