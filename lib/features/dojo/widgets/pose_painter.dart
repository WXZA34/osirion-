import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final bool showSkeleton;
  final Set<PoseLandmarkType> faultyLandmarks;

  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection, {
    this.showSkeleton = true,
    this.faultyLandmarks = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showSkeleton) return;

    final paintLineNormal =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.cyan;

    final paintLineFaulty =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0 // Un peu plus épais pour l'alerte
          ..color = Colors.redAccent;

    final paintPoint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.greenAccent;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            translateX(
              landmark.x,
              size,
              absoluteImageSize,
              rotation,
              cameraLensDirection,
            ),
            translateY(
              landmark.y,
              size,
              absoluteImageSize,
              rotation,
              cameraLensDirection,
            ),
          ),
          4,
          paintPoint,
        );
      });

      void paintLineBetween(PoseLandmarkType type1, PoseLandmarkType type2) {
        final landmark1 = pose.landmarks[type1];
        final landmark2 = pose.landmarks[type2];
        
        if (landmark1 != null && landmark2 != null) {
          // Si l'un des deux points est marqué en faute, on utilise le pinceau rouge
          final isFaulty = faultyLandmarks.contains(type1) || faultyLandmarks.contains(type2);
          final activePaint = isFaulty ? paintLineFaulty : paintLineNormal;

          canvas.drawLine(
            Offset(
              translateX(landmark1.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark1.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            Offset(
              translateX(landmark2.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark2.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            activePaint,
          );
        }
      }

      // Bras
      paintLineBetween(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
      );
      paintLineBetween(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      paintLineBetween(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
      );
      paintLineBetween(
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
      );

      // Torse
      paintLineBetween(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
      );
      paintLineBetween(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      paintLineBetween(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
      );
      paintLineBetween(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      // Jambes
      paintLineBetween(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      paintLineBetween(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      paintLineBetween(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      paintLineBetween(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }

  double translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        // Caméra arrière portrait : pas d'inversion X
        return x *
            canvasSize.width /
            (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        // Caméra avant portrait : inversion X (miroir)
        return canvasSize.width -
            x *
                canvasSize.width /
                (Platform.isIOS ? imageSize.width : imageSize.height);
      default:
        return x * canvasSize.width / imageSize.width;
    }
  }

  double translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y *
            canvasSize.height /
            (Platform.isIOS ? imageSize.height : imageSize.width);
      default:
        return y * canvasSize.height / imageSize.height;
    }
  }
}
