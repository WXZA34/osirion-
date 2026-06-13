import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_math_service.dart';
import 'i_valerion_counter.dart';

enum SquatState { up, down, unknown }

class SquatCounter implements IValerionCounter {
  int _count = 0;
  SquatState _state = SquatState.unknown;

  @override
  bool get isCalibrating => false;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => {};

  @override
  String get name => "SQUATS";

  @override
  int get targetReps => 0;

  @override
  String get currentState {
    switch (_state) {
      case SquatState.up:
        return "DEBOUT";
      case SquatState.down:
        return "ACCROUPI";
      default:
        return "ATTENTE";
    }
  }

  @override
  int get count => _count;

  @override
  bool processPose(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Calcul de l'angle du genou gauche et droit (Hanche, Genou, Cheville)
    final leftKneeAngle = PoseMathService.getAngle(
      leftHip,
      leftKnee,
      leftAnkle,
    );
    final rightKneeAngle = PoseMathService.getAngle(
      rightHip,
      rightKnee,
      rightAnkle,
    );

    double activeAngle = -1.0;
    if (leftKneeAngle > 0 && rightKneeAngle > 0) {
      activeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    } else if (leftKneeAngle > 0) {
      activeAngle = leftKneeAngle;
    } else if (rightKneeAngle > 0) {
      activeAngle = rightKneeAngle;
    }

    if (activeAngle > 0) {
      // Genou tendu = debout (> 160°)
      if (activeAngle > 160.0) {
        if (_state == SquatState.down) {
          _state = SquatState.up;
          _count++;
          return true; // Squat validé à la remontée
        }
        _state = SquatState.up;
      }
      // Genou plié = accroupi (< 100° - parallèle minimum)
      else if (activeAngle < 100.0) {
        if (_state == SquatState.up || _state == SquatState.unknown) {
          _state = SquatState.down;
        }
      }
    }
    return false;
  }

  @override
  void reset() {
    _count = 0;
    _state = SquatState.unknown;
  }
}
