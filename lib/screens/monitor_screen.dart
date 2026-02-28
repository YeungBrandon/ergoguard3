// ============================================================
// screens/monitor_screen.dart
// Real-time camera monitoring screen with pose overlay
// Front camera + Gyroscope based analysis
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/posture_model.dart';
import '../services/pose_service.dart';
import '../services/alert_service.dart';
import '../services/reba_service.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/angle_bars.dart';
import '../widgets/micro_learning_card.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});
  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;

  // Services
  late PoseService _poseService;
  late AlertService _alertService;

  // State
  PostureData? _latestPose;
  late ShiftSession _session;
  late WorkerSector _sector;
  late bool _cantonese;
  bool _monitoring = true;
  bool _showMicroLearn = false;
  int _consecutiveHighRisk = 0;
  Timer? _uiTimer;
  Timer? _breakTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poseService = PoseService();
    _alertService = AlertService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _sector = args?['sector'] ?? WorkerSector.construction;
    _cantonese = args?['cantonese'] ?? true;
    _session = ShiftSession(startTime: DateTime.now(), sector: _sector);
    _initCamera();
    _alertService.announceShiftStart(sector: _sector, cantonese: _cantonese);
    _startBreakReminder();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      // Find front camera
      final front = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      // Start image stream for pose detection
      await _cameraController!.startImageStream(_onCameraFrame);

      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _onCameraFrame(CameraImage image) async {
    if (!_monitoring) return;

    final pose = await _poseService.processFrame(
      image,
      _cameraController!.description.sensorOrientation,
      _sector,
    );

    if (pose == null) return;

    // Update session
    _session.postureHistory.add(pose);
    switch (pose.riskLevel) {
      case RiskLevel.low:
        _session.totalLowRiskSeconds++;
        _consecutiveHighRisk = 0;
        break;
      case RiskLevel.medium:
        _session.totalMediumRiskSeconds++;
        _consecutiveHighRisk = 0;
        break;
      case RiskLevel.high:
      case RiskLevel.veryHigh:
        _session.totalHighRiskSeconds += 2;
        _consecutiveHighRisk++;
        break;
    }

    // Trigger alerts
    if (pose.alerts.isNotEmpty) {
      await _alertService.triggerAlert(
        riskLevel: pose.riskLevel,
        alerts: pose.alerts,
        cantonese: _cantonese,
      );
    }

    // Show micro-learning after sustained high risk
    if (_consecutiveHighRisk > 20 && !_showMicroLearn) {
      if (mounted) setState(() => _showMicroLearn = true);
    }

    if (mounted) setState(() => _latestPose = pose);
  }

  void _startBreakReminder() {
    _breakTimer = Timer.periodic(const Duration(minutes: 45), (_) {
      if (_monitoring) {
        _alertService.announceBreak(cantonese: _cantonese);
        _session.microBreaksTaken++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview (full screen)
          if (_cameraReady && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3498DB)),
                  SizedBox(height: 16),
                  Text('Initialising camera...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          // Dark gradient overlay for UI readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(child: _buildTopBar()),

          // Pose skeleton overlay
          if (_latestPose != null)
            Positioned.fill(child: _buildPoseOverlay()),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // Micro-learning overlay
          if (_showMicroLearn)
            Positioned.fill(
              child: MicroLearningCard(
                sector: _sector,
                task: _latestPose?.detectedTask ?? TaskType.unknown,
                cantonese: _cantonese,
                onDismiss: () {
                  setState(() {
                    _showMicroLearn = false;
                    _consecutiveHighRisk = 0;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Sector badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _sector == WorkerSector.construction
                  ? const Color(0xFF1A5276)
                  : const Color(0xFF6C3483),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sector == WorkerSector.construction
                      ? Icons.construction
                      : Icons.restaurant,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _sector == WorkerSector.construction
                      ? (_cantonese ? '建造業' : 'Construction')
                      : (_cantonese ? '飲食業' : 'Catering'),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Session duration
          _buildTimer(),
          const SizedBox(width: 12),
          // Pause/Resume
          GestureDetector(
            onTap: () => setState(() => _monitoring = !_monitoring),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _monitoring
                    ? const Color(0xFF27AE60).withOpacity(0.8)
                    : const Color(0xFFE74C3C).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _monitoring ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final duration = _session.duration;
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPoseOverlay() {
    if (_latestPose == null) return const SizedBox();
    final pose = _latestPose!;
    final color = pose.riskColor;

    return CustomPaint(
      painter: PoseOverlayPainter(riskColor: color),
    );
  }

  Widget _buildBottomPanel() {
    final pose = _latestPose;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pose?.riskColor.withOpacity(0.5) ?? Colors.white24,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // REBA Score + Risk Level
          Row(
            children: [
              // Gauge
              SizedBox(
                width: 80,
                height: 80,
                child: RiskGauge(
                  score: pose?.rebaScore ?? 0,
                  maxScore: 15,
                  color: pose?.riskColor ?? Colors.white24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REBA: ${pose?.rebaScore ?? '--'}',
                      style: TextStyle(
                        color: pose?.riskColor ?? Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _cantonese
                          ? (pose?.riskLabelZh ?? '等待分析...')
                          : (pose?.riskLabelEn ?? 'Waiting for analysis...'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_cantonese ? '偵測任務' : 'Task'}: ${_cantonese ? RebaService.taskNameZh(pose?.detectedTask ?? TaskType.unknown) : RebaService.taskNameEn(pose?.detectedTask ?? TaskType.unknown)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Fatigue index
              Column(
                children: [
                  Text(
                    _cantonese ? '疲勞指數' : 'Fatigue',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_session.fatigueIndex.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _fatigueColor(_session.fatigueIndex),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_cantonese ? '建議休息' : 'Break in'}\n${_session.predictedBreakIn}min',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Angle bars
          if (pose != null) ...[
            AngleBars(
              neckAngle: pose.neckAngle,
              trunkAngle: pose.trunkAngle,
              leftShoulderAngle: pose.leftShoulderAngle,
              rightShoulderAngle: pose.rightShoulderAngle,
              cantonese: _cantonese,
            ),
            const SizedBox(height: 12),
          ],

          // Active alerts
          if (pose != null && pose.alerts.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pose.riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pose.riskColor.withOpacity(0.4)),
              ),
              child: Text(
                pose.alerts.first,
                style: TextStyle(color: pose.riskColor, fontSize: 12, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Gyro info (small)
          if (pose != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rotate_90_degrees_ccw, color: Colors.white24, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Gyro: X${pose.gyroX.toStringAsFixed(1)} Y${pose.gyroY.toStringAsFixed(1)} Z${pose.gyroZ.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _fatigueColor(double index) {
    if (index < 30) return const Color(0xFF27AE60);
    if (index < 60) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseService.dispose();
    _alertService.dispose();
    _breakTimer?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }
}

// Simple pose skeleton painter
class PoseOverlayPainter extends CustomPainter {
  final Color riskColor;
  PoseOverlayPainter({required this.riskColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = riskColor.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw risk indicator ring in center
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.35),
      40,
      paint..color = riskColor.withOpacity(0.3),
    );

    // Crosshair for body centre detection guide
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.1),
      Offset(size.width / 2, size.height * 0.9),
      guidePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height / 2),
      Offset(size.width * 0.9, size.height / 2),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) => old.riskColor != riskColor;
}
