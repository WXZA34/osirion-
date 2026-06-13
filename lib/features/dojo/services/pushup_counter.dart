import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_math_service.dart';

enum PushupState { up, down, unknown }

class PushupCounter {
  int count = 0;
  PushupState _state = PushupState.unknown;

  /// Analyse la pose fournie et incrémente le compteur si une pompe est complétée.
  /// Retourne `true` si une nouvelle pompe vient d'être validée lors de cette frame.
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

    // On utilise le côté le plus visible / valide
    double activeAngle = -1.0;
    if (leftElbowAngle > 0 && rightElbowAngle > 0) {
      activeAngle =
          (leftElbowAngle + rightElbowAngle) /
          2; // On moyenne la flexion des bras
    } else if (leftElbowAngle > 0) {
      activeAngle = leftElbowAngle;
    } else if (rightElbowAngle > 0) {
      activeAngle = rightElbowAngle;
    }

    // Machine d'état simplifiée
    if (activeAngle > 0) {
      if (activeAngle > 150.0) {
        // Bras quasiment tendus (position "Haut")
        if (_state == PushupState.down) {
          _state = PushupState.up;
          count++;
          return true; // Une pompe vient d'être complétée !
        }
        _state = PushupState.up;
      } else if (activeAngle < 90.0) {
        // Bras pliés à 90 degrés ou moins (position "Bas" valide pour une pompe)
        if (_state == PushupState.up || _state == PushupState.unknown) {
          _state = PushupState.down;
        }
      }
    }

    return false;
  }
}
