import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

abstract class IValerionCounter {
  /// Nom affiché sur le HUD (ex: "POMPES")
  String get name;

  /// Cible (nombre de répétitions suggérées, optionnel)
  int get targetReps;

  /// État actuel (ex: HAUT, BAS, DESCEND...)
  String get currentState;

  /// Obtient le nombre de répétitions effectuées.
  int get count;

  /// État de calibration (true si l'IA analyse encore la morphologie)
  bool get isCalibrating;

  /// Liste des points en défaut de posture pour coloration rouge
  Set<PoseLandmarkType> get faultyLandmarks;

  /// Vérifie la posture et renvoie (true) si une répétition est validée.
  bool processPose(Pose pose);

  /// Remet à zéro le compteur de répétitions interne, ou l'état.
  void reset();
}
