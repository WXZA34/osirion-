import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/main_navigation_shell.dart';
import '../../core/providers/repository_providers.dart';
import 'models/exercise_config.dart';

class DojoReportScreen extends ConsumerStatefulWidget {
  final ExerciseConfig config;
  final int completedReps;

  const DojoReportScreen({
    super.key,
    required this.config,
    required this.completedReps,
  });

  @override
  ConsumerState<DojoReportScreen> createState() => _DojoReportScreenState();
}

class _DojoReportScreenState extends ConsumerState<DojoReportScreen> {
  bool _isSaving = false;
  int _earnedXp = 0;
  int _earnedAether = 0;

  @override
  void initState() {
    super.initState();
    _earnedXp = widget.completedReps * widget.config.defaultXpPerRep;
    _earnedAether = widget.completedReps ~/ 10; // 1 Aether toutes les 10 reps
  }

  Future<void> _saveAndExit() async {
    setState(() => _isSaving = true);
    try {
      final authState = ref.read(authStateProvider);
      final uid = authState.value?.id;
      final navigator = Navigator.of(context, rootNavigator: true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (uid != null) {
        final repo = ref.read(valerionRepositoryProvider);
        final now = DateTime.now();
        final localDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        final user = ref.read(userProfileProvider).valueOrNull;
        final arcId = user?.activeArcId;

        await repo.addWorkoutResults(
          uid,
          widget.completedReps,
          _earnedXp,
          _earnedAether,
          localDateStr: localDateStr,
          arcId: arcId,
        );

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Résultats synchronisés !"),
            backgroundColor: Colors.greenAccent,
          ),
        );

        // Retour Sécurisé à la porte d'entrée de l'application via le Root Navigator
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationShell()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint("Erreur sauvegarde \$e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              "RAPPORT DE MISSION",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            _buildStatBox(
              "${widget.config.name.toUpperCase()} VALIDÉ(E)S",
              widget.completedReps.toString(),
              Colors.cyanAccent,
            ),
            const SizedBox(height: 20),
            _buildStatBox(
              "XP OBTENU (FORCE)",
              "+\$$_earnedXp",
              Colors.orangeAccent,
            ),
            const SizedBox(height: 20),
            _buildStatBox(
              "AETHER RÉCOLTÉ",
              "+\$$_earnedAether",
              Colors.purpleAccent,
            ),
            const SizedBox(height: 60),
            if (_isSaving)
              const CircularProgressIndicator(color: Colors.cyanAccent)
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                onPressed: _saveAndExit,
                child: const Text(
                  "VALIDER L'ENTRAÎNEMENT",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
