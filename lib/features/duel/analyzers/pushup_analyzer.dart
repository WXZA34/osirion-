import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_analyzer.dart';

class PushupAnalyzer extends ExerciseAnalyzer {
  bool _isDown = false;

  @override
  int processPose(Pose pose) {
    // Get landmarks for Left Arm (we could check both and average, or pick the one with better visibility)
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (leftShoulder == null || leftElbow == null || leftWrist == null) return 0;

    final angle = getAngle(leftShoulder, leftElbow, leftWrist);
    if (angle == -1.0) return 0; // Low confidence

    // Pushup logic
    // Down state: elbow angle is < 90 degrees
    // Up state: elbow angle is > 160 degrees
    if (angle < 90.0) {
      _isDown = true;
    } else if (angle > 160.0 && _isDown) {
      _isDown = false;
      return 1; // 1 rep completed
    }

    return 0;
  }
}
