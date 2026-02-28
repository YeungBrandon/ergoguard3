// ============================================================
// models/posture_model.dart
// Data models for ergonomic analysis
// ============================================================

import 'package:flutter/material.dart';

enum RiskLevel { low, medium, high, veryHigh }
enum WorkerSector { construction, catering }
enum TaskType {
  // Construction
  rebarTying, concretePour, heavyLifting, scaffolding, generalConstruction,
  // Catering
  chopping, wokStirring, counterStanding, dishwashing, generalCatering,
  // Universal
  unknown,
}

class PostureData {
  final DateTime timestamp;
  final double neckAngle;        // degrees from vertical
  final double trunkAngle;       // degrees from vertical
  final double leftShoulderAngle;
  final double rightShoulderAngle;
  final double leftElbowAngle;
  final double rightElbowAngle;
  final double leftKneeAngle;
  final double rightKneeAngle;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final RiskLevel riskLevel;
  final int rebaScore;
  final TaskType detectedTask;
  final List<String> alerts;

  PostureData({
    required this.timestamp,
    required this.neckAngle,
    required this.trunkAngle,
    required this.leftShoulderAngle,
    required this.rightShoulderAngle,
    required this.leftElbowAngle,
    required this.rightElbowAngle,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.riskLevel,
    required this.rebaScore,
    required this.detectedTask,
    required this.alerts,
  });

  Color get riskColor {
    switch (riskLevel) {
      case RiskLevel.low: return const Color(0xFF27AE60);
      case RiskLevel.medium: return const Color(0xFFF39C12);
      case RiskLevel.high: return const Color(0xFFE74C3C);
      case RiskLevel.veryHigh: return const Color(0xFF8E44AD);
    }
  }

  String get riskLabelEn {
    switch (riskLevel) {
      case RiskLevel.low: return 'Low Risk';
      case RiskLevel.medium: return 'Medium Risk';
      case RiskLevel.high: return 'High Risk';
      case RiskLevel.veryHigh: return 'Very High Risk';
    }
  }

  String get riskLabelZh {
    switch (riskLevel) {
      case RiskLevel.low: return '低風險';
      case RiskLevel.medium: return '中等風險';
      case RiskLevel.high: return '高風險';
      case RiskLevel.veryHigh: return '極高風險';
    }
  }
}

class ShiftSession {
  final DateTime startTime;
  DateTime? endTime;
  final WorkerSector sector;
  List<PostureData> postureHistory = [];
  int totalHighRiskSeconds = 0;
  int totalMediumRiskSeconds = 0;
  int totalLowRiskSeconds = 0;
  int microBreaksTaken = 0;

  ShiftSession({
    required this.startTime,
    required this.sector,
  });

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  double get highRiskPercentage {
    final total = totalHighRiskSeconds + totalMediumRiskSeconds + totalLowRiskSeconds;
    if (total == 0) return 0;
    return (totalHighRiskSeconds / total) * 100;
  }

  double get averageRebaScore {
    if (postureHistory.isEmpty) return 0;
    return postureHistory.map((p) => p.rebaScore).reduce((a, b) => a + b) /
        postureHistory.length;
  }

  // Fatigue prediction: cumulative exposure index (0–100)
  double get fatigueIndex {
    final minutesElapsed = duration.inMinutes;
    final highRiskWeight = totalHighRiskSeconds * 2.0;
    final mediumRiskWeight = totalMediumRiskSeconds * 1.0;
    final exposure = (highRiskWeight + mediumRiskWeight) / 60;
    return ((exposure / (minutesElapsed + 1)) * 100).clamp(0, 100);
  }

  int get predictedBreakIn {
    // Minutes until recommended break based on fatigue trajectory
    final fi = fatigueIndex;
    if (fi > 70) return 5;
    if (fi > 50) return 15;
    if (fi > 30) return 30;
    return 60;
  }
}
