import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  late final PoseDetector _poseDetector;

  PoseDetectorService() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<List<Pose>> processImage(InputImage inputImage) async {
    return await _poseDetector.processImage(inputImage);
  }

  void close() {
    _poseDetector.close();
  }
}
