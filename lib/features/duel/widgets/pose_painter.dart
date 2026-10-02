import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    // Glowing Neon Paint for the Core Body
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.cyanAccent.withOpacity(0.8);
      
    final coreGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Glowing Amber for Left Limbs
    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.amberAccent;
      
    final leftGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.amber.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Glowing Orange for Right Limbs
    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.deepOrangeAccent;
      
    final rightGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.deepOrangeAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Joint Marker
    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    for (final pose in poses) {
      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType, Paint glowType) {
        final joint1 = pose.landmarks[type1];
        final joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          final x1 = _translateX(joint1.x, rotation, size, absoluteImageSize);
          final y1 = _translateY(joint1.y, rotation, size, absoluteImageSize);
          final x2 = _translateX(joint2.x, rotation, size, absoluteImageSize);
          final y2 = _translateY(joint2.y, rotation, size, absoluteImageSize);
          
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowType);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paintType);
        }
      }

      // Draw arms
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint, leftGlow);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint, leftGlow);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightPaint, rightGlow);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint, rightGlow);

      // Draw Body
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint, coreGlow);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint, coreGlow);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paint, coreGlow);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, paint, coreGlow);

      // Draw legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint, leftGlow);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint, leftGlow);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint, rightGlow);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint, rightGlow);

      // Draw Joints on top of lines
      pose.landmarks.forEach((_, landmark) {
        final x = _translateX(landmark.x, rotation, size, absoluteImageSize);
        final y = _translateY(landmark.y, rotation, size, absoluteImageSize);
        canvas.drawCircle(Offset(x, y), 6, coreGlow); // Outer glow
        canvas.drawCircle(Offset(x, y), 3, jointPaint); // Inner bright joint
      });
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }

  double _translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / absoluteImageSize.height;
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / absoluteImageSize.height;
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double _translateY(double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }
}
