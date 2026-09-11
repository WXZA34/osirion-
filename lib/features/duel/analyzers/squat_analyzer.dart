import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_analyzer.dart';

class SquatAnalyzer extends ExerciseAnalyzer {
  bool _isDown = false;

  @override
  int processPose(Pose pose) {
    // Get landmarks for Left Leg
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null) return 0;

    final angle = getAngle(leftHip, leftKnee, leftAnkle);
    if (angle == -1.0) return 0; // Low confidence

    // Squat logic
    // Down state: knee angle < 100 degrees (parallel or below)
    // Up state: knee angle > 160 degrees (standing up)
    if (angle < 100.0) {
      _isDown = true;
    } else if (angle > 160.0 && _isDown) {
      _isDown = false;
      return 1; // 1 rep completed
    }

    return 0;
  }
}
