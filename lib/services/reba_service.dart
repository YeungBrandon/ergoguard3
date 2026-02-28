// ============================================================
// services/reba_service.dart
// REBA (Rapid Entire Body Assessment) scoring engine
// Hong Kong Labour Dept + OSHC aligned
// ============================================================

import 'dart:math';
import '../models/posture_model.dart';

class RebaService {
  // ── REBA Table A: Neck + Trunk + Legs ──────────────────────

  /// Calculate neck score (1–3)
  static int neckScore(double angleDegrees) {
    final angle = angleDegrees.abs();
    if (angle <= 20) return 1;
    if (angle <= 45) return 2;
    return 3;
  }

  /// Calculate trunk score (1–5)
  static int trunkScore(double angleDegrees) {
    final angle = angleDegrees.abs();
    if (angle <= 5) return 1;
    if (angle <= 20) return 2;
    if (angle <= 60) return 3;
    return 4;
  }

  /// Calculate leg score (1–2)
  static int legScore(double leftKneeAngle, double rightKneeAngle) {
    // Well-supported bilateral standing = 1
    // Unstable or one-legged = 2
    final asymmetry = (leftKneeAngle - rightKneeAngle).abs();
    return asymmetry > 20 ? 2 : 1;
  }

  // ── REBA Table B: Upper Arm + Lower Arm + Wrist ────────────

  /// Upper arm score (1–6)
  static int upperArmScore(double shoulderAngle) {
    final angle = shoulderAngle.abs();
    if (angle <= 20) return 1;
    if (angle <= 45) return 2;
    if (angle <= 90) return 3;
    return 4;
  }

  /// Lower arm score (1–2)
  static int lowerArmScore(double elbowAngle) {
    // 60–100° is ideal
    if (elbowAngle >= 60 && elbowAngle <= 100) return 1;
    return 2;
  }

  // ── Table A Score Lookup (simplified) ──────────────────────
  static int tableAScore(int neck, int trunk, int legs) {
    // REBA Table A lookup (simplified continuous approximation)
    final base = (trunk - 1) * 5 + neck;
    return (base + legs).clamp(1, 9);
  }

  // ── Table B Score Lookup ────────────────────────────────────
  static int tableBScore(int upperArm, int lowerArm) {
    return (upperArm + lowerArm - 1).clamp(1, 8);
  }

  // ── Table C: Combine A and B ────────────────────────────────
  static int tableCScore(int scoreA, int scoreB) {
    // Simplified Table C approximation
    return ((scoreA + scoreB) / 2).round().clamp(1, 12);
  }

  // ── Final REBA Score ────────────────────────────────────────
  static int calculateRebaScore({
    required double neckAngle,
    required double trunkAngle,
    required double leftShoulderAngle,
    required double rightShoulderAngle,
    required double leftElbowAngle,
    required double rightElbowAngle,
    required double leftKneeAngle,
    required double rightKneeAngle,
    bool forceCoupling = false,
    bool repetitiveMotion = false,
  }) {
    final neck = neckScore(neckAngle);
    final trunk = trunkScore(trunkAngle);
    final legs = legScore(leftKneeAngle, rightKneeAngle);

    final upperArm = max(
      upperArmScore(leftShoulderAngle),
      upperArmScore(rightShoulderAngle),
    );
    final lowerArm = max(
      lowerArmScore(leftElbowAngle),
      lowerArmScore(rightElbowAngle),
    );

    final scoreA = tableAScore(neck, trunk, legs);
    final scoreB = tableBScore(upperArm, lowerArm);
    int scoreC = tableCScore(scoreA, scoreB);

    // Activity modifiers
    if (repetitiveMotion) scoreC += 1;
    if (forceCoupling) scoreC += 1;

    return scoreC.clamp(1, 15);
  }

  // ── Risk Level from REBA Score ──────────────────────────────
  static RiskLevel riskFromRebaScore(int score) {
    if (score <= 3) return RiskLevel.low;
    if (score <= 7) return RiskLevel.medium;
    if (score <= 10) return RiskLevel.high;
    return RiskLevel.veryHigh;
  }

  // ── Generate Alerts ─────────────────────────────────────────
  static List<String> generateAlerts({
    required double neckAngle,
    required double trunkAngle,
    required double leftShoulderAngle,
    required double rightShoulderAngle,
    required double leftElbowAngle,
    required double rightElbowAngle,
    required WorkerSector sector,
    required double gyroMagnitude,
  }) {
    final List<String> alerts = [];

    if (neckAngle.abs() > 20) {
      alerts.add('頸部前傾過大\nNeck bent too far forward (${neckAngle.abs().toStringAsFixed(0)}°)');
    }
    if (trunkAngle.abs() > 20) {
      alerts.add('腰背彎曲超標\nTrunk bent excessively (${trunkAngle.abs().toStringAsFixed(0)}°)');
    }
    if (leftShoulderAngle.abs() > 45 || rightShoulderAngle.abs() > 45) {
      alerts.add('肩膊抬高過度\nShoulder raised too high');
    }
    if (gyroMagnitude > 1.5) {
      alerts.add('動作幅度過大\nExcessive body movement detected');
    }

    // Sector-specific
    if (sector == WorkerSector.construction && trunkAngle.abs() > 30) {
      alerts.add('危險！搬運時請彎膝不彎腰\nDanger! Bend knees not back when lifting');
    }
    if (sector == WorkerSector.catering && neckAngle.abs() > 25) {
      alerts.add('廚房工作：請調整工作台高度\nAdjust counter height to reduce neck strain');
    }

    return alerts;
  }

  // ── Task Auto-Detection from Pose ───────────────────────────
  static TaskType detectTask({
    required double trunkAngle,
    required double leftShoulderAngle,
    required double rightShoulderAngle,
    required double leftElbowAngle,
    required double rightElbowAngle,
    required double gyroMagnitude,
    required WorkerSector sector,
  }) {
    final asymShoulders = (leftShoulderAngle - rightShoulderAngle).abs();
    final avgShoulder = (leftShoulderAngle.abs() + rightShoulderAngle.abs()) / 2;
    final avgElbow = (leftElbowAngle + rightElbowAngle) / 2;

    if (sector == WorkerSector.construction) {
      if (trunkAngle.abs() > 40 && avgShoulder < 30) return TaskType.heavyLifting;
      if (asymShoulders > 30 && gyroMagnitude > 0.8) return TaskType.rebarTying;
      if (avgElbow < 70 && avgShoulder > 60) return TaskType.scaffolding;
      return TaskType.generalConstruction;
    } else {
      if (gyroMagnitude > 1.2 && asymShoulders > 20) return TaskType.wokStirring;
      if (trunkAngle.abs() > 15 && avgElbow < 90) return TaskType.chopping;
      if (trunkAngle.abs() < 10 && avgShoulder < 20) return TaskType.counterStanding;
      if (trunkAngle.abs() > 25) return TaskType.dishwashing;
      return TaskType.generalCatering;
    }
  }

  // ── Task display names ───────────────────────────────────────
  static String taskNameZh(TaskType task) {
    switch (task) {
      case TaskType.rebarTying: return '綁鋼筋';
      case TaskType.concretePour: return '澆混凝土';
      case TaskType.heavyLifting: return '重物搬運';
      case TaskType.scaffolding: return '棚架工作';
      case TaskType.chopping: return '切菜';
      case TaskType.wokStirring: return '炒鑊';
      case TaskType.counterStanding: return '站立服務';
      case TaskType.dishwashing: return '洗碗';
      default: return '一般工作';
    }
  }

  static String taskNameEn(TaskType task) {
    switch (task) {
      case TaskType.rebarTying: return 'Rebar Tying';
      case TaskType.concretePour: return 'Concrete Pour';
      case TaskType.heavyLifting: return 'Heavy Lifting';
      case TaskType.scaffolding: return 'Scaffolding';
      case TaskType.chopping: return 'Chopping';
      case TaskType.wokStirring: return 'Wok Stirring';
      case TaskType.counterStanding: return 'Counter Standing';
      case TaskType.dishwashing: return 'Dishwashing';
      default: return 'General Work';
    }
  }
}
