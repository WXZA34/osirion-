import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_math_service.dart';
import '../../../core/services/tts_service.dart';
import 'i_valerion_counter.dart';

enum ElbowState { up, down, unknown }

class ElbowEngine implements IValerionCounter {
  final String exerciseId;
  final double sensitivity;
  int _count = 0;
  ElbowState _state = ElbowState.unknown;
  final TtsService _tts = TtsService();

  // --- Calibration (FIX #4 : Stabilité 1.5s + validateur perspective) ---
  bool _isCalibrating = true;
  DateTime? _calibrationStartTime;
  double? _lastShoulderWidth;
  double _calibratedUpThreshold = 165.0;
  double _calibratedDownThreshold = 80.0;

  // --- Posture tactique ---
  final Set<PoseLandmarkType> _faultyLandmarks = {};

  // --- TRIPLE SERRURE ANTI-FANTÔMES (Version Renforcée) ---
  DateTime? _lastRepTime;         // Serrure 1 : Temporelle (800ms)
  double? _shoulderYAtBottom;     // Serrure 2 : Spatiale (35px)
  double? _minAngleReached;       // Serrure 3 : Amplitude (40°)
  int _downStateFrames = 0;       // Hystérésis : stabilité 3 frames

  // --- Cooldown TTS 3 secondes ---
  DateTime? _lastVoiceFeedback;

  ElbowEngine({
    required this.exerciseId,
    required this.sensitivity,
  });

  @override
  bool get isCalibrating => _isCalibrating;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => _faultyLandmarks;

  @override
  String get name {
    if (exerciseId.contains("pushups")) return "POMPES";
    if (exerciseId.contains("tractions") || exerciseId.contains("pull_ups")) return "TRACTIONS";
    if (exerciseId.contains("dips")) return "DIPS";
    return "MOTEUR COUDE";
  }

  @override
  int get targetReps => 0;

  @override
  String get currentState {
    switch (_state) {
      case ElbowState.up: return "HAUT";
      case ElbowState.down: return "BAS";
      default: return "ATTENTE";
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

    final leftShoulder  = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow     = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist     = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist    = pose.landmarks[PoseLandmarkType.rightWrist];

    final leftAngle  = PoseMathService.getAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = PoseMathService.getAngle(rightShoulder, rightElbow, rightWrist);

    double activeAngle = -1.0;
    if (leftAngle > 0 && rightAngle > 0) {
      activeAngle = (leftAngle + rightAngle) / 2;
    } else if (leftAngle > 0) {
      activeAngle = leftAngle;
    } else if (rightAngle > 0) {
      activeAngle = rightAngle;
    }

    if (activeAngle > 0) {
      final shoulderMark = leftShoulder ?? rightShoulder;
      final hipMark = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];

      final trunkAlignment = PoseMathService.getAlignment(shoulderMark, hipMark);
      final bool isVertical = (trunkAlignment - 90).abs() < 45;

      final upThreshold   = _calibratedUpThreshold   - (sensitivity * 20.0);
      final downThreshold = _calibratedDownThreshold  + (sensitivity * 25.0); // Un peu plus large pour capture initiale

      _checkPosture(pose);

      if (isVertical) {
        // --- MODE VERTICAL (TRACTIONS / DIPS) ---
        if (exerciseId.contains("tractions") || exerciseId.contains("pull_ups")) {
          if (activeAngle < downThreshold) {
            _handleDownState(activeAngle, shoulderMark?.y);
          } else if (activeAngle > upThreshold) {
            if (_state == ElbowState.down && _validateTripleLock(shoulderMark?.y, activeAngle)) {
              _handleRepCompletion(pose);
              return true;
            }
            _state = ElbowState.up;
            _downStateFrames = 0;
          }
        } else {
          // Dips
          if (activeAngle > upThreshold) {
            if (_state == ElbowState.down && _validateTripleLock(shoulderMark?.y, activeAngle)) {
              _handleRepCompletion(pose);
              return true;
            }
            _state = ElbowState.up;
            _downStateFrames = 0;
          } else if (activeAngle < downThreshold) {
            _handleDownState(activeAngle, shoulderMark?.y);
          }
        }
      } else {
        // --- MODE HORIZONTAL (POMPES) ---
        if (activeAngle > upThreshold) {
          if (_state == ElbowState.down && _validateTripleLock(shoulderMark?.y, activeAngle)) {
            _handleRepCompletion(pose);
            return true;
          }
          _state = ElbowState.up;
          _downStateFrames = 0;
        } else if (activeAngle < downThreshold) {
          _handleDownState(activeAngle, shoulderMark?.y);
        }
      }
    }
    return false;
  }

  void _handleDownState(double currentAngle, double? shoulderY) {
    _downStateFrames++;
    // Hystérésis : Il faut au moins 3 images dans la zone basse pour valider l'état
    if (_downStateFrames >= 3) {
      if (_state != ElbowState.down) {
        _shoulderYAtBottom = shoulderY;
        _minAngleReached = currentAngle;
      } else {
        // Continuer de traquer l'angle le plus fermé
        if (_minAngleReached != null && currentAngle < _minAngleReached!) {
          _minAngleReached = currentAngle;
        }
      }
      _state = ElbowState.down;
    }
  }

  /// TRIPLE SERRURE ANTI-FANTÔMES
  bool _validateTripleLock(double? currentShoulderY, double currentAngle) {
    final now = DateTime.now();

    // 1. Serrure Temporelle : 800ms minimum
    final timeSinceLast = _lastRepTime == null ? 9999 : now.difference(_lastRepTime!).inMilliseconds;
    if (timeSinceLast < 800) return false;

    // 2. Serrure Spatiale : Déplacement de l'épaule de 35px minimum (Image coordinate)
    if (_shoulderYAtBottom != null && currentShoulderY != null) {
      final spatialDelta = (currentShoulderY - _shoulderYAtBottom!).abs();
      if (spatialDelta < 35) return false;
    }

    // 3. Serrure Angulaire (Hystérésis) : Amplitude de 40° minimum depuis l'angle min
    if (_minAngleReached != null) {
      final angularDelta = (currentAngle - _minAngleReached!).abs();
      if (angularDelta < 40) return false;
    }

    return true;
  }

  void _handleRepCompletion(Pose pose) {
    _state = ElbowState.up;
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
    if (exerciseId.contains("pushups")) {
      final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
      final hip   = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
      final ankle = pose.landmarks[PoseLandmarkType.leftAnkle] ?? pose.landmarks[PoseLandmarkType.rightAnkle];

      final alignment = PoseMathService.getAngle(shoulder, hip, ankle);
      final bool isValid = alignment > (155.0 - (sensitivity * 10.0));

      if (!isValid) {
        _faultyLandmarks.addAll([
          PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
          PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
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
    _tts.speakInstruction("Gardez le dos droit !");
  }

  @override
  void reset() {
    _count = 0;
    _state = ElbowState.unknown;
    _lastRepTime = null;
    _shoulderYAtBottom = null;
    _minAngleReached = null;
    _downStateFrames = 0;
    _lastVoiceFeedback = null;
    _calibrationStartTime = null;
    _lastShoulderWidth = null;
    _isCalibrating = true;
  }
}
