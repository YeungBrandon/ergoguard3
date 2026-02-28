// ============================================================
// services/pose_service.dart
// Wraps ML Kit Pose Detection + angle calculations
// Uses FRONT camera only + gyroscope for motion compensation
// ============================================================

import 'dart:math';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/posture_model.dart';
import 'reba_service.dart';

class PoseService {
  late PoseDetector _poseDetector;
  bool _isProcessing = false;

  // Gyroscope state
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;
  double _gyroMagnitude = 0;

  PoseService() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
    _startGyroListener();
  }

  void _startGyroListener() {
    gyroscopeEventStream().listen((GyroscopeEvent event) {
      _gyroX = event.x;
      _gyroY = event.y;
      _gyroZ = event.z;
      _gyroMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    });
  }

  /// Process a camera frame and return PostureData
  Future<PostureData?> processFrame(
    CameraImage image,
    int sensorOrientation,
    WorkerSector sector,
  ) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, sensorOrientation);
      if (inputImage == null) return null;

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;
      return _analysePose(pose, sector);
    } catch (e) {
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, int sensorOrientation) {
    try {
      final ui.WriteBuffer allBytes = ui.WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      InputImageRotation rotation;
      switch (sensorOrientation) {
        case 90: rotation = InputImageRotation.rotation90deg; break;
        case 180: rotation = InputImageRotation.rotation180deg; break;
        case 270: rotation = InputImageRotation.rotation270deg; break;
        default: rotation = InputImageRotation.rotation0deg;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: ui.Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  PostureData _analysePose(Pose pose, WorkerSector sector) {
    // Extract key landmarks
    final landmarks = pose.landmarks;

    final nose = landmarks[PoseLandmarkType.nose];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    // Calculate angles
    final neckAngle = _calculateNeckAngle(nose, leftShoulder, rightShoulder);
    final trunkAngle = _calculateTrunkAngle(leftShoulder, rightShoulder, leftHip, rightHip);
    final leftShoulderAngle = _calculateShoulderAngle(leftShoulder, leftHip, leftElbow);
    final rightShoulderAngle = _calculateShoulderAngle(rightShoulder, rightHip, rightElbow);
    final leftElbowAngle = _calculateElbowAngle(leftShoulder, leftElbow, leftWrist);
    final rightElbowAngle = _calculateElbowAngle(rightShoulder, rightElbow, rightWrist);
    final leftKneeAngle = _calculateKneeAngle(leftHip, leftKnee, null);
    final rightKneeAngle = _calculateKneeAngle(rightHip, rightKnee, null);

    // REBA scoring
    final rebaScore = RebaService.calculateRebaScore(
      neckAngle: neckAngle,
      trunkAngle: trunkAngle,
      leftShoulderAngle: leftShoulderAngle,
      rightShoulderAngle: rightShoulderAngle,
      leftElbowAngle: leftElbowAngle,
      rightElbowAngle: rightElbowAngle,
      leftKneeAngle: leftKneeAngle,
      rightKneeAngle: rightKneeAngle,
      repetitiveMotion: _gyroMagnitude > 0.8,
    );

    final riskLevel = RebaService.riskFromRebaScore(rebaScore);

    final alerts = RebaService.generateAlerts(
      neckAngle: neckAngle,
      trunkAngle: trunkAngle,
      leftShoulderAngle: leftShoulderAngle,
      rightShoulderAngle: rightShoulderAngle,
      leftElbowAngle: leftElbowAngle,
      rightElbowAngle: rightElbowAngle,
      sector: sector,
      gyroMagnitude: _gyroMagnitude,
    );

    final detectedTask = RebaService.detectTask(
      trunkAngle: trunkAngle,
      leftShoulderAngle: leftShoulderAngle,
      rightShoulderAngle: rightShoulderAngle,
      leftElbowAngle: leftElbowAngle,
      rightElbowAngle: rightElbowAngle,
      gyroMagnitude: _gyroMagnitude,
      sector: sector,
    );

    return PostureData(
      timestamp: DateTime.now(),
      neckAngle: neckAngle,
      trunkAngle: trunkAngle,
      leftShoulderAngle: leftShoulderAngle,
      rightShoulderAngle: rightShoulderAngle,
      leftElbowAngle: leftElbowAngle,
      rightElbowAngle: rightElbowAngle,
      leftKneeAngle: leftKneeAngle,
      rightKneeAngle: rightKneeAngle,
      gyroX: _gyroX,
      gyroY: _gyroY,
      gyroZ: _gyroZ,
      riskLevel: riskLevel,
      rebaScore: rebaScore,
      detectedTask: detectedTask,
      alerts: alerts,
    );
  }

  // ── Angle Calculation Helpers ────────────────────────────────

  double _calculateNeckAngle(
    PoseLandmark? nose,
    PoseLandmark? leftShoulder,
    PoseLandmark? rightShoulder,
  ) {
    if (nose == null || leftShoulder == null || rightShoulder == null) return 0;
    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    return _angleBetweenPoints(
      midShoulderX, midShoulderY,
      midShoulderX, midShoulderY - 100, // straight up reference
      nose.x, nose.y,
    );
  }

  double _calculateTrunkAngle(
    PoseLandmark? leftShoulder,
    PoseLandmark? rightShoulder,
    PoseLandmark? leftHip,
    PoseLandmark? rightHip,
  ) {
    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) return 0;

    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final midHipX = (leftHip.x + rightHip.x) / 2;
    final midHipY = (leftHip.y + rightHip.y) / 2;

    // Angle from vertical
    final dx = midShoulderX - midHipX;
    final dy = midShoulderY - midHipY;
    return atan2(dx, -dy) * 180 / pi;
  }

  double _calculateShoulderAngle(
    PoseLandmark? shoulder,
    PoseLandmark? hip,
    PoseLandmark? elbow,
  ) {
    if (shoulder == null || hip == null || elbow == null) return 0;
    return _angleBetweenPoints(
      hip.x, hip.y,
      shoulder.x, shoulder.y,
      elbow.x, elbow.y,
    );
  }

  double _calculateElbowAngle(
    PoseLandmark? shoulder,
    PoseLandmark? elbow,
    PoseLandmark? wrist,
  ) {
    if (shoulder == null || elbow == null || wrist == null) return 90;
    return _angleBetweenPoints(
      shoulder.x, shoulder.y,
      elbow.x, elbow.y,
      wrist.x, wrist.y,
    );
  }

  double _calculateKneeAngle(
    PoseLandmark? hip,
    PoseLandmark? knee,
    PoseLandmark? ankle,
  ) {
    if (hip == null || knee == null) return 180; // assume straight
    if (ankle == null) return 175;
    return _angleBetweenPoints(
      hip.x, hip.y,
      knee.x, knee.y,
      ankle.x, ankle.y,
    );
  }

  double _angleBetweenPoints(
    double ax, double ay,  // point A
    double bx, double by,  // vertex B
    double cx, double cy,  // point C
  ) {
    final v1x = ax - bx;
    final v1y = ay - by;
    final v2x = cx - bx;
    final v2y = cy - by;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0;
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  void dispose() {
    _poseDetector.close();
  }
}
