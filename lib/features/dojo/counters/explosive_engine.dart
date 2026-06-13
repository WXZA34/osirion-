import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_math_service.dart';
import '../../../core/services/tts_service.dart';
import 'i_valerion_counter.dart';

enum ExplosiveState { up, down, unknown }

class ExplosiveEngine implements IValerionCounter {
  final String exerciseId;
  final double sensitivity;
  int _count = 0;
  ExplosiveState _state = ExplosiveState.unknown;
  final TtsService _tts = TtsService();

  ExplosiveEngine({
    required this.exerciseId,
    required this.sensitivity,
  });

  @override
  bool get isCalibrating => false;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => {};

  @override
  String get name {
    if (exerciseId.contains("jumping")) return "JUMPING JACKS";
    return "MOTEUR EXPLOSIF";
  }

  @override
  int get targetReps => 0;

  @override
  String get currentState {
    switch (_state) {
      case ExplosiveState.up: return "HAUT";
      case ExplosiveState.down: return "BAS";
      default: return "ATTENTE";
    }
  }

  @override
  int get count => _count;

  @override
  bool processPose(Pose pose) {
    if (exerciseId.contains("jumping")) {
      return _processJumpingJacks(pose);
    }
    return false;
  }

  bool _processJumpingJacks(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist == null || rightWrist == null || leftAnkle == null || rightAnkle == null || leftShoulder == null || rightShoulder == null) return false;

    final feetDist = PoseMathService.getDistance(leftAnkle, rightAnkle);
    final shoulderDist = PoseMathService.getDistance(leftShoulder, rightShoulder);

    if (shoulderDist <= 0) return false;

    final openFeetThreshold = 1.2 + (sensitivity * 0.4);

    bool isHandsHigh = leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
    bool isStar = isHandsHigh && (feetDist > shoulderDist * openFeetThreshold);
    bool isClosed = !isHandsHigh && (feetDist < shoulderDist * 1.5);

    if (isStar) {
      _state = ExplosiveState.up;
    } else if (isClosed) {
      if (_state == ExplosiveState.up) {
        _validateRep();
        return true;
      }
      _state = ExplosiveState.down;
    }

    return false;
  }

  void _validateRep() {
    _count++;
    _state = ExplosiveState.down;
    HapticFeedback.lightImpact();
    _tts.speak("$_count");
  }

  @override
  void reset() {
    _count = 0;
    _state = ExplosiveState.unknown;
  }
}
