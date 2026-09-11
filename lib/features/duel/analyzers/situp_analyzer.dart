import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_analyzer.dart';

class SitupAnalyzer extends ExerciseAnalyzer {
  bool _isUp = false;

  @override
  int processPose(Pose pose) {
    // Get landmarks for Left side (shoulder, hip, knee)
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null) return 0;

    final angle = getAngle(leftShoulder, leftHip, leftKnee);
    if (angle == -1.0) return 0; // Low confidence

    // Sit-up logic
    // Down state (lying flat): angle > 140
    // Up state (crunching): angle < 75
    if (angle < 75.0) {
      _isUp = true;
    } else if (angle > 140.0 && _isUp) {
      _isUp = false;
      return 1; // 1 rep completed
    }

    return 0;
  }
}
