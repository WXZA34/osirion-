import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_math_service.dart';
import '../../../core/services/tts_service.dart';
import 'i_valerion_counter.dart';

enum KneeState { up, down, unknown }

class KneeEngine implements IValerionCounter {
  final String exerciseId;
  final double sensitivity;
  int _count = 0;
  KneeState _state = KneeState.unknown;
  final TtsService _tts = TtsService();

  // --- FIX #4 : Calibration stable 1.5s + validateur perspective ---
  bool _isCalibrating = true;
  final Set<PoseLandmarkType> _faultyLandmarks = {};
  DateTime? _calibrationStartTime;
  double? _lastShoulderWidth;

  // --- TRIPLE SERRURE ANTI-FANTÔMES (Version Renforcée) ---
  DateTime? _lastRepTime;         // Serrure 1 : Temporelle (800ms)
  double? _hipYAtBottom;          // Serrure 2 : Spatiale (35px)
  double? _minAngleReached;       // Serrure 3 : Amplitude (40°)
  int _downStateFrames = 0;       // Hystérésis : stabilité 3 frames

  // --- FIX #5 : Cooldown TTS 3s ---
  DateTime? _lastVoiceFeedback;

  KneeEngine({
    required this.exerciseId,
    required this.sensitivity,
  });

  @override
  bool get isCalibrating => _isCalibrating;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => _faultyLandmarks;

  @override
  String get name {
    if (exerciseId.contains("squat")) return "SQUATS";
    if (exerciseId.contains("fente") || exerciseId.contains("lunge")) return "FENTES";
    return "MOTEUR GENOU";
  }

  @override
  int get targetReps => 0;

  @override
  String get currentState {
    switch (_state) {
      case KneeState.up:   return "DEBOUT";
      case KneeState.down: return "ACCROUPI";
      default:             return "ATTENTE";
    }
  }

  @override
  int get count => _count;

  @override
  bool processPose(Pose pose) {
    _faultyLandmarks.clear();

    // --- CALIBRATION ---
    if (_isCalibrating) {
      final leftShoulder  = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

      if (leftShoulder != null && rightShoulder != null) {
        final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
        if (_lastShoulderWidth != null && (shoulderWidth - _lastShoulderWidth!).abs() > 30) {
          _calibrationStartTime = null;
        }
        _lastShoulderWidth = shoulderWidth;
        _calibrationStartTime ??= DateTime.now();

        final elapsed = DateTime.now().difference(_calibrationStartTime!).inMilliseconds;
        if (elapsed >= 1500) {
          _isCalibrating = false;
          _tts.speakInstruction("Position validée, à vous !");
        }
      }
      return false;
    }

    final leftHip   = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee  = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    final rightHip   = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee  = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    final leftAngle  = PoseMathService.getAngle(leftHip, leftKnee, leftAnkle);
    final rightAngle = PoseMathService.getAngle(rightHip, rightKnee, rightAnkle);

    double activeAngle = -1.0;
    if (leftAngle > 0 && rightAngle > 0) {
      activeAngle = (leftAngle + rightAngle) / 2;
    } else if (leftAngle > 0) {
      activeAngle = leftAngle;
    } else if (rightAngle > 0) {
      activeAngle = rightAngle;
    }

    if (activeAngle > 0) {
      final upThreshold   = 165.0 - (sensitivity * 15.0);
      final downThreshold =  95.0 + (sensitivity * 15.0);

      final hipMark = leftHip ?? rightHip;

      if (activeAngle > upThreshold) {
        // Validation TRIPLE SERRURE avant de valider la répétition
        if (_state == KneeState.down && _validateTripleLock(hipMark?.y, activeAngle)) {
          _handleRepCompletion(pose);
          return true;
        }
        _state = KneeState.up;
        _downStateFrames = 0; // Reset si on remonte avant validation stability
      } else if (activeAngle < downThreshold) {
        _handleDownState(activeAngle, hipMark?.y);
      }
    }
    return false;
  }

  void _handleDownState(double currentAngle, double? hipY) {
    _downStateFrames++;
    // Hystérésis : Il faut au moins 3 images dans la zone basse pour valider l'état
    if (_downStateFrames >= 3) {
      if (_state != KneeState.down) {
        _hipYAtBottom = hipY;
        _minAngleReached = currentAngle;
      } else {
        // Continuer de traquer l'angle le plus fermé
        if (_minAngleReached != null && currentAngle < _minAngleReached!) {
          _minAngleReached = currentAngle;
        }
      }
      _state = KneeState.down;
    }
  }

  /// TRIPLE SERRURE ANTI-FANTÔMES
  bool _validateTripleLock(double? currentHipY, double currentAngle) {
    final now = DateTime.now();

    // 1. Serrure Temporelle : 800ms minimum entre deux reps
    final timeSinceLast = _lastRepTime == null ? 9999 : now.difference(_lastRepTime!).inMilliseconds;
    if (timeSinceLast < 800) return false;

    // 2. Serrure Spatiale : La hanche a bien bougé d'au moins 35px
    if (_hipYAtBottom != null && currentHipY != null) {
      final spatialDelta = (currentHipY - _hipYAtBottom!).abs();
      if (spatialDelta < 35) return false;
    }

    // 3. Serrure Angulaire : Amplitude de 40° minimum depuis l'angle min
    if (_minAngleReached != null) {
      final angularDelta = (currentAngle - _minAngleReached!).abs();
      if (angularDelta < 40) return false;
    }

    return true;
  }

  void _handleRepCompletion(Pose pose) {
    _state = KneeState.up;
    _downStateFrames = 0;
    _lastRepTime = DateTime.now();

    final bool isPostureValid = _checkPosture(pose);

    if (isPostureValid) {
      _count++;
      HapticFeedback.lightImpact();
      _tts.speak("$_count");
    } else {
      _triggerBadPostureFeedback();
    }
  }

  bool _checkPosture(Pose pose) {
    if (exerciseId.contains("squat")) {
      final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
      final hip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];

      final alignment = PoseMathService.getAlignment(shoulder, hip);
      final bool isValid = alignment > 45.0 && alignment < 135.0;

      if (!isValid) {
        _faultyLandmarks.addAll([
          PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
        ]);
      }
      return isValid;
    }
    return true;
  }

  void _triggerBadPostureFeedback() {
    final now = DateTime.now();
    if (_lastVoiceFeedback != null && now.difference(_lastVoiceFeedback!).inSeconds < 3) {
      HapticFeedback.heavyImpact();
      return;
    }
    _lastVoiceFeedback = now;
    HapticFeedback.heavyImpact();
    _tts.speakInstruction("Gardez le buste droit !");
  }

  @override
  void reset() {
    _count = 0;
    _state = KneeState.unknown;
    _lastRepTime = null;
    _hipYAtBottom = null;
    _minAngleReached = null;
    _downStateFrames = 0;
    _lastVoiceFeedback = null;
    _calibrationStartTime = null;
    _lastShoulderWidth = null;
    _isCalibrating = true;
  }
}
