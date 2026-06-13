import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMathService {
  static const double _radToDeg = 180.0 / pi;

  /// Calcule l'angle (en degrés) formé par 3 points (p1, p2, p3), où p2 est le sommet de l'angle.
  static double getAngle(PoseLandmark? p1, PoseLandmark? p2, PoseLandmark? p3) {
    if (p1 == null || p2 == null || p3 == null) {
      return -1.0;
    }

    final double radians =
        atan2(p3.y - p2.y, p3.x - p2.x) - atan2(p1.y - p2.y, p1.x - p2.x);
    double angle = (radians * _radToDeg).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }

  /// Calcule la distance euclidienne entre deux points.
  static double getDistance(PoseLandmark? p1, PoseLandmark? p2) {
    if (p1 == null || p2 == null) return -1.0;
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calcule l'alignement vertical/horizontal d'un segment par rapport à un axe.
  /// Retourne un angle de 0 à 180°.
  static double getAlignment(PoseLandmark? p1, PoseLandmark? p2) {
    if (p1 == null || p2 == null) return -1.0;
    final double radians = atan2(p2.y - p1.y, p2.x - p1.x);
    return (radians * _radToDeg).abs();
  }
}
