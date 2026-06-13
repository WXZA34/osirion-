import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_math_service.dart';
import 'i_valerion_counter.dart';

enum PushupState { up, down, unknown }

class PushupCounter implements IValerionCounter {
  int _count = 0;
  PushupState _state = PushupState.unknown;
  final double sensitivity; // De 0.0 (très strict) à 1.0 (très permissif)

  PushupCounter({this.sensitivity = 0.7});

  @override
  bool get isCalibrating => false;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => {};

  @override
  String get name => "POMPES";

  @override
  int get targetReps => 0;

  @override
  String get currentState {
    switch (_state) {
      case PushupState.up:
        return "HAUT";
      case PushupState.down:
        return "BAS";
      default:
        return "ATTENTE";
    }
  }

  @override
  int get count => _count;

  @override
  bool processPose(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Calcul de l'angle du coude gauche et droit
    final leftElbowAngle = PoseMathService.getAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    final rightElbowAngle = PoseMathService.getAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );

    double activeAngle = -1.0;
    if (leftElbowAngle > 0 && rightElbowAngle > 0) {
      activeAngle = (leftElbowAngle + rightElbowAngle) / 2;
    } else if (leftElbowAngle > 0) {
      activeAngle = leftElbowAngle;
    } else if (rightElbowAngle > 0) {
      activeAngle = rightElbowAngle;
    }

    if (activeAngle > 0) {
      // Calcul de l'angle de tolérance.
      // Si sensitivity = 1.0 (permissif), l'angle requis redescend vers 140°
      // Si sensitivity = 0.0 (strict), l'angle requis monte vers 165°
      // Sensibilité par défaut (0.7) => 165 - (0.7 * 25) = 147.5°
      final targetUpAngle = 165.0 - (sensitivity * 25.0);

      if (activeAngle > targetUpAngle) {
        if (_state == PushupState.down) {
          _state = PushupState.up;
          _count++;
          HapticFeedback.lightImpact(); // Feedback immersif
          return true; // Pompe validée
        }
        _state = PushupState.up;
      } else if (activeAngle < 90.0) {
        if (_state == PushupState.up || _state == PushupState.unknown) {
          _state = PushupState.down;
        }
      }
    }
    return false;
  }

  @override
  void reset() {
    _count = 0;
    _state = PushupState.unknown;
  }
}
