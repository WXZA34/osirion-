import 'package:flutter/material.dart';

class ExerciseType {
  final String id;
  final String title;
  final String subtitle;
  final String iconEmoji;
  final String muscleTarget;
  final Color themeColor;

  const ExerciseType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.muscleTarget,
    required this.themeColor,
  });

  static const List<ExerciseType> allExercises = [
    ExerciseType(
      id: "pushups",
      title: "Pompes",
      subtitle: "Force du Haut du Corps",
      iconEmoji: "💪",
      muscleTarget: "Pecs, Triceps, Épaules",
      themeColor: Colors.amber,
    ),
    ExerciseType(
      id: "squats",
      title: "Squats",
      subtitle: "Puissance des Jambes",
      iconEmoji: "🦵",
      muscleTarget: "Quadriceps, Fessiers",
      themeColor: Colors.deepOrangeAccent,
    ),
    ExerciseType(
      id: "situps",
      title: "Abdos",
      subtitle: "Endurance Core",
      iconEmoji: "⚡",
      muscleTarget: "Sangle Abdominale",
      themeColor: Colors.cyanAccent,
    ),
  ];
}

class ExerciseSelectionSheet extends StatefulWidget {
  final Function(ExerciseType) onExerciseSelected;

  const ExerciseSelectionSheet({
    Key? key,
    required this.onExerciseSelected,
  }) : super(key: key);

  static void show(BuildContext context, Function(ExerciseType) onExerciseSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExerciseSelectionSheet(onExerciseSelected: onExerciseSelected),
    );
  }

  @override
  State<ExerciseSelectionSheet> createState() => _ExerciseSelectionSheetState();
}

class _ExerciseSelectionSheetState extends State<ExerciseSelectionSheet> {
  String? selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0C10), // DarkBg
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            "SÉLECTIONNEZ VOTRE ARMEMENT",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "L'arbitre IA s'adaptera à l'exercice choisi. Préparez-vous à transpirer.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 24),

          // Exercise Options
          ...ExerciseType.allExercises.map((exercise) {
            final isSelected = selectedExerciseId == exercise.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedExerciseId = exercise.id;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? exercise.themeColor.withOpacity(0.15) : const Color(0xFF15171C), // DarkSurface
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? exercise.themeColor : Colors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Emoji Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: exercise.themeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: exercise.themeColor.withOpacity(0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(exercise.iconEmoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.title.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? exercise.themeColor : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              exercise.subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Cible : ${exercise.muscleTarget}",
                              style: TextStyle(
                                color: exercise.themeColor.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Radio check
                      if (isSelected)
                        Icon(Icons.check_circle, color: exercise.themeColor, size: 28)
                      else
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedExerciseId != null
                  ? () {
                      final exercise = ExerciseType.allExercises.firstWhere((e) => e.id == selectedExerciseId);
                      Navigator.pop(context); // Close the sheet
                      widget.onExerciseSelected(exercise);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedExerciseId != null
                    ? ExerciseType.allExercises.firstWhere((e) => e.id == selectedExerciseId).themeColor
                    : const Color(0xFF2C2F33), // DarkSurfaceVariant
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: const Color(0xFF2C2F33),
              ),
              child: Text(
                "ENTRER DANS L'ARÈNE",
                style: TextStyle(
                  color: selectedExerciseId != null ? const Color(0xFF121316) : Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
