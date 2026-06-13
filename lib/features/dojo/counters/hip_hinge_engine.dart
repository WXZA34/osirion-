import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_math_service.dart';
import '../../../core/services/tts_service.dart';
import 'i_valerion_counter.dart';

enum HipState { open, closed, unknown }

class HipHingeEngine implements IValerionCounter {
  final String exerciseId;
  final double sensitivity;
  int _count = 0;
  HipState _state = HipState.unknown;
  final TtsService _tts = TtsService();
  final Set<PoseLandmarkType> _faultyLandmarks = {};

  // --- FIX #4 : Calibration stable 1.5s ---
  bool _isCalibrating = true;
  DateTime? _calibrationStartTime;
  double? _lastShoulderWidth;

  // --- FIX #3 : Double Serrure anti-faux positifs ---
  DateTime? _lastRepTime;    // Serrure temporelle : 800ms minimum
  double? _hipAngleAtMin;    // Serrure angulaire : angle minimum atteint

  // --- FIX #5 : Cooldown TTS 3s ---
  DateTime? _lastVoiceFeedback;

  HipHingeEngine({
    required this.exerciseId,
    required this.sensitivity,
  });

  @override
  bool get isCalibrating => _isCalibrating;

  @override
  Set<PoseLandmarkType> get faultyLandmarks => _faultyLandmarks;

  @override
  String get name {
    if (exerciseId.contains("relevs")) return "ABDOMINAUX";
    if (exerciseId.contains("v_ups"))  return "V-UPS";
    if (exerciseId.contains("pike"))   return "PIKE PUSHUPS";
    return "MOTEUR HANCHE";
  }

  @override
  int get targetReps => 0;

  @override
  String get currentState {
    switch (_state) {
      case HipState.open:   return "OUVERT";
      case HipState.closed: return "FERMÉ";
      default:              return "ATTENTE";
    }
  }

  @override
  int get count => _count;

  @override
  bool processPose(Pose pose) {
    _faultyLandmarks.clear();

    // --- CALIBRATION (FIX #4) ---
    if (_isCalibrating) {
      final leftShoulder  = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

      if (leftShoulder != null && rightShoulder != null) {
        final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

        // Mouvement trop important → reset du timer de stabilité
        if (_lastShoulderWidth != null &&
            (shoulderWidth - _lastShoulderWidth!).abs() > 30) {
          _calibrationStartTime = null;
        }
        _lastShoulderWidth = shoulderWidth;
        _calibrationStartTime ??= DateTime.now();

        final elapsed = DateTime.now()
            .difference(_calibrationStartTime!)
            .inMilliseconds;
        if (elapsed >= 1500) {
          _isCalibrating = false;
          _tts.speakInstruction("Position validée, à vous !");
        }
      }
      return false;
    }

    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ??
        pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip  = pose.landmarks[PoseLandmarkType.leftHip] ??
        pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee] ??
        pose.landmarks[PoseLandmarkType.rightKnee];

    final hipAngle = PoseMathService.getAngle(shoulder, hip, knee);

    if (hipAngle > 0) {
      // Seuil "Ouvert" (corps tendu) : entre 170° (strict) et 150° (permissif)
      final openThreshold   = 170.0 - (sensitivity * 20.0);
      // Seuil "Fermé" (contraction) : entre 60° (strict) et 90° (permissif)
      final closedThreshold =  60.0 + (sensitivity * 30.0);

      if (hipAngle < closedThreshold) {
        // Mémoriser l'angle minimum atteint pour la serrure
        _hipAngleAtMin = hipAngle;
        _state = HipState.closed;
      } else if (hipAngle > openThreshold) {
        // FIX #3 : Double serrure avant de valider
        if (_state == HipState.closed && _validateDoubleLock()) {
          _validateRep();
          return true;
        }
        _state = HipState.open;
      }
    }
    return false;
  }

  /// FIX #3 — Double Serrure anti-faux positifs
  bool _validateDoubleLock() {
    final now = DateTime.now();

    // Serrure temporelle : 800ms minimum entre deux reps
    final timeSinceLast = _lastRepTime == null
        ? 9999
        : now.difference(_lastRepTime!).inMilliseconds;
    if (timeSinceLast < 800) return false;

    // Serrure angulaire : s'assurer que l'angle a vraiment atteint la zone fermée
    // (évite les micro-oscillations autour du seuil)
    final closedThreshold = 60.0 + (sensitivity * 30.0);
    if (_hipAngleAtMin != null && _hipAngleAtMin! > closedThreshold * 1.1) {
      return false;
    }

    return true;
  }

  void _validateRep() {
    // Si l'angle minimum atteint est trop élevé → mauvaise amplitude → feedback
    final closedThreshold = 60.0 + (sensitivity * 30.0);
    final bool goodAmplitude = _hipAngleAtMin != null &&
        _hipAngleAtMin! <= closedThreshold;

    if (goodAmplitude) {
      _count++;
      _state = HipState.open;
      _lastRepTime = DateTime.now();
      _hipAngleAtMin = null;
      HapticFeedback.lightImpact();
      _tts.speak("$_count");
    } else {
      _state = HipState.open;
      _lastRepTime = DateTime.now();
      _hipAngleAtMin = null;
      _triggerBadPostureFeedback();
    }
  }

  /// FIX #5 — Cooldown 3s entre feedbacks vocaux
  void _triggerBadPostureFeedback() {
    final now = DateTime.now();
    if (_lastVoiceFeedback != null &&
        now.difference(_lastVoiceFeedback!).inSeconds < 3) {
      HapticFeedback.heavyImpact();
      return;
    }
    _lastVoiceFeedback = now;
    HapticFeedback.heavyImpact();
    _tts.speakInstruction("Contractez les abdominaux !");
  }

  @override
  void reset() {
    _count = 0;
    _state = HipState.unknown;
    _lastRepTime = null;
    _hipAngleAtMin = null;
    _lastVoiceFeedback = null;
    _calibrationStartTime = null;
    _lastShoulderWidth = null;
    _isCalibrating = true;
  }
}
