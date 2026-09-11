import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

abstract class ExerciseAnalyzer {
  /// The minimum confidence score required for a landmark to be considered valid
  final double confidenceThreshold = 0.65;

  /// Process the pose and return the number of repetitions completed in this frame.
  /// Usually returns 1 if a rep was just completed, otherwise 0.
  int processPose(Pose pose);

  /// Helper to calculate angle between three points (A, B, C) where B is the vertex.
  double getAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    if (first.likelihood < confidenceThreshold ||
        middle.likelihood < confidenceThreshold ||
        last.likelihood < confidenceThreshold) {
      return -1.0; // Invalid angle due to low confidence
    }

    final dx1 = first.x - middle.x;
    final dy1 = first.y - middle.y;
    final dx2 = last.x - middle.x;
    final dy2 = last.y - middle.y;

    final dot = dx1 * dx2 + dy1 * dy2;
    final cross = dx1 * dy2 - dy1 * dx2;

    var angle = math.atan2(cross, dot) * (180.0 / math.pi);
    angle = angle.abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }
}
