import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class CameraUtils {
  static InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraController controller,
    int cameraIndex,
  ) {
    final sensorOrientation = controller.description.sensorOrientation;
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (controller.description.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate format
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      // On Android, CameraImage is usually YUV420, but ML Kit expects NV21 for some inputs.
      // However, the latest plugin versions handle YUV_420_888 essentially as NV21 usually
      // But strict validation might fail if the raw value doesn't match exactly.
      // Let's rely on the raw bytes mostly.
      if (format == null) return null;
    }

    // Since we are primarily targeting stream on generic devices, we assume single plane for iOS/BGRA
    // and multiple for Android/YUV.

    if (image.planes.isEmpty) return null;

    // Compose InputImage
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow, // Main plane
      ),
    );
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    if (planes.length == 1) return planes.first.bytes;

    final allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}
