import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'i_valerion_counter.dart';

/// Compteur par défaut pour les exercices du Codex qui n'ont pas encore
/// de logique mathématique IA d'implémentée.
class MockCounter implements IValerionCounter {
  final String exerciseName;
  int _count = 0;

  MockCounter(this.exerciseName);

  @override
  bool get isCalibrating => false;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => {};

  @override
  String get name => exerciseName.toUpperCase();

  @override
  int get targetReps => 0;

  @override
  String get currentState => "MOCK_AI_WAITING";

  @override
  int get count => _count;

  @override
  bool processPose(Pose pose) {
    // Dans un vrai cas, on n'incrémenterait pas tout seul.
    // Pour des besoins de tests de l'UX, on peut imaginer un tap manuel
    // sur l'écran d'exercice ou un bouton "Simuler Répétition".
    return false;
  }

  /// Méthode utilitaire pour incrémenter manuellement l'exercice non-implémenté (Mode Guide manuel)
  void incrementManual() {
    _count++;
  }

  @override
  void reset() {
    _count = 0;
  }
}
