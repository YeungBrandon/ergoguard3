// ============================================================
// services/alert_service.dart
// Cantonese-first TTS + Haptic alert engine
// Includes OSHC-aligned micro-learning tips
// ============================================================

import 'package:flutter_tts/flutter_tts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../models/posture_model.dart';

class AlertService {
  final FlutterTts _tts = FlutterTts();
  DateTime? _lastAlertTime;
  static const _alertCooldown = Duration(seconds: 15);
  bool _isSpeaking = false;

  AlertService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-HK'); // Cantonese Traditional Chinese
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(0.9);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
  }

  Future<void> triggerAlert({
    required RiskLevel riskLevel,
    required List<String> alerts,
    required bool cantonese,
  }) async {
    final now = DateTime.now();
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!) < _alertCooldown) return;
    if (_isSpeaking) return;

    _lastAlertTime = now;

    // Haptic pattern based on risk
    switch (riskLevel) {
      case RiskLevel.low: break;
      case RiskLevel.medium:
        await Haptics.vibrate(HapticsType.light);
        break;
      case RiskLevel.high:
        await Haptics.vibrate(HapticsType.medium);
        await Future.delayed(const Duration(milliseconds: 200));
        await Haptics.vibrate(HapticsType.medium);
        break;
      case RiskLevel.veryHigh:
        for (int i = 0; i < 3; i++) {
          await Haptics.vibrate(HapticsType.heavy);
          await Future.delayed(const Duration(milliseconds: 150));
        }
        break;
    }

    // Voice alert
    if (alerts.isNotEmpty && riskLevel.index >= RiskLevel.medium.index) {
      final firstAlert = alerts.first;
      // Extract Cantonese portion (before \n)
      final parts = firstAlert.split('\n');
      final text = cantonese ? parts[0] : (parts.length > 1 ? parts[1] : parts[0]);
      await _tts.speak(text);
    }
  }

  // Micro-break reminder
  Future<void> announceBreak({required bool cantonese}) async {
    const zhText = '建議您現在休息五分鐘，做一些伸展運動';
    const enText = 'Time for a 5-minute stretch break to reduce injury risk';
    await Haptics.vibrate(HapticsType.selection);
    await _tts.setLanguage(cantonese ? 'zh-HK' : 'en-HK');
    await _tts.speak(cantonese ? zhText : enText);
  }

  // Shift start message
  Future<void> announceShiftStart({
    required WorkerSector sector,
    required bool cantonese,
  }) async {
    String zhText, enText;
    if (sector == WorkerSector.construction) {
      zhText = 'ErgoGuard已啟動。建造業姿勢監測開始。請保持安全姿勢。';
      enText = 'ErgoGuard started. Construction posture monitoring active.';
    } else {
      zhText = 'ErgoGuard已啟動。飲食業姿勢監測開始。請注意頸部和腰部姿勢。';
      enText = 'ErgoGuard started. Catering posture monitoring active.';
    }
    await _tts.setLanguage(cantonese ? 'zh-HK' : 'en-HK');
    await _tts.speak(cantonese ? zhText : enText);
  }

  void dispose() {
    _tts.stop();
  }
}

// ============================================================
// OSHC-aligned micro-learning tips database
// ============================================================
class MicroLearningTips {
  static List<MicroTip> getTips(WorkerSector sector, TaskType task) {
    final general = _generalTips;
    final sectorTips = sector == WorkerSector.construction
        ? _constructionTips
        : _cateringTips;

    return [...general, ...sectorTips]..shuffle();
  }

  static final List<MicroTip> _generalTips = [
    MicroTip(
      titleZh: '正確搬運姿勢',
      titleEn: 'Safe Lifting Technique',
      descZh: '搬運重物時，請屈膝蹲下，保持腰背挺直。避免彎腰直接提起重物，以防腰椎受傷。',
      descEn: 'When lifting, bend your knees and keep your back straight. Never bend at the waist.',
      sourceZh: '來源：勞工處《體力處理作業指引》',
      sourceEn: 'Source: Labour Dept Manual Handling Guidelines',
      iconCode: 0xe547, // fitness_center
    ),
    MicroTip(
      titleZh: '定期休息',
      titleEn: 'Regular Rest Breaks',
      descZh: '每45–60分鐘應休息5–10分鐘並做伸展運動，以減少肌肉疲勞和肌肉骨骼損傷風險。',
      descEn: 'Take 5–10 minute breaks every 45–60 minutes. Stretch to reduce MSD risk.',
      sourceZh: '來源：職業安全健康局',
      sourceEn: 'Source: OSHC',
      iconCode: 0xe8d6, // self_improvement
    ),
  ];

  static final List<MicroTip> _constructionTips = [
    MicroTip(
      titleZh: '鋼筋綁紮安全',
      titleEn: 'Safe Rebar Tying',
      descZh: '綁紮鋼筋時，應使用專用工具，避免長時間彎腰。可用輔助跪墊減少膝蓋壓力。',
      descEn: 'Use proper tools for rebar tying. Use knee pads and avoid prolonged bending.',
      sourceZh: '來源：職業安全健康局建造業資源',
      sourceEn: 'Source: OSHC Construction Resources',
      iconCode: 0xe3f7, // construction
    ),
    MicroTip(
      titleZh: '肩膀保護',
      titleEn: 'Shoulder Protection',
      descZh: '進行架設棚架等高空工作時，應盡量避免雙臂長時間抬高過頭，並定期休息放鬆肩膊。',
      descEn: 'Avoid sustained overhead work. Rotate tasks to reduce shoulder strain.',
      sourceZh: '來源：勞工處職安健指引',
      sourceEn: 'Source: Labour Dept OSH Guidelines',
      iconCode: 0xe532, // accessibility_new
    ),
  ];

  static final List<MicroTip> _cateringTips = [
    MicroTip(
      titleZh: '廚房工作台高度',
      titleEn: 'Kitchen Counter Height',
      descZh: '工作台高度應與手肘齊平（站立時）。台面過低會導致長期彎腰，增加腰背受傷風險。',
      descEn: 'Counter should be elbow-height when standing. Low surfaces cause back strain.',
      sourceZh: '來源：職業安全健康局飲食業資源',
      sourceEn: 'Source: OSHC Catering Resources',
      iconCode: 0xef55, // restaurant
    ),
    MicroTip(
      titleZh: '炒鑊技巧',
      titleEn: 'Safe Wok Technique',
      descZh: '炒鑊時應站穩，用腿部和核心力量輔助手臂動作。避免只用腕部力量，以防腱鞘炎。',
      descEn: 'Use leg and core strength when stirring wok. Avoid repetitive wrist-only motion.',
      sourceZh: '來源：職業安全健康局',
      sourceEn: 'Source: OSHC',
      iconCode: 0xef55, // restaurant
    ),
  ];
}

class MicroTip {
  final String titleZh;
  final String titleEn;
  final String descZh;
  final String descEn;
  final String sourceZh;
  final String sourceEn;
  final int iconCode;

  MicroTip({
    required this.titleZh,
    required this.titleEn,
    required this.descZh,
    required this.descEn,
    required this.sourceZh,
    required this.sourceEn,
    required this.iconCode,
  });
}
