import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Filtre Passe-Bas exponentiel appliqué aux coordonnées des landmarks.
/// Élimine le jitter visuel sans introduire de latence perceptible.
/// alpha = 0.35 → bon équilibre réactivité / stabilité
class PoseSmoother {
  static const double _alpha = 0.35;

  // Historique lissé : landmarkType → (x, y)
  final Map<PoseLandmarkType, _SmoothedPoint> _history = {};

  /// Lisse une liste de poses et retourne les poses avec coordonnées filtrées.
  List<Pose> smooth(List<Pose> rawPoses) {
    if (rawPoses.isEmpty) return rawPoses;

    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in rawPoses.first.landmarks.entries) {
      final type = entry.key;
      final raw = entry.value;

      final prev = _history[type];
      if (prev == null) {
        // Première frame : pas de lissage, on prend la valeur brute
        _history[type] = _SmoothedPoint(raw.x, raw.y);
        smoothedLandmarks[type] = raw;
      } else {
        // Lissage exponentiel : smoothed = α·raw + (1−α)·prev
        final sx = _alpha * raw.x + (1 - _alpha) * prev.x;
        final sy = _alpha * raw.y + (1 - _alpha) * prev.y;
        _history[type] = _SmoothedPoint(sx, sy);

        // Recréer le landmark avec les coordonnées lissées
        smoothedLandmarks[type] = PoseLandmark(
          type: type,
          x: sx,
          y: sy,
          z: raw.z,
          likelihood: raw.likelihood,
        );
      }
    }

    return [Pose(landmarks: smoothedLandmarks)];
  }

  /// Réinitialise l'historique (ex: entre deux sessions)
  void reset() => _history.clear();
}

class _SmoothedPoint {
  final double x;
  final double y;
  const _SmoothedPoint(this.x, this.y);
}
