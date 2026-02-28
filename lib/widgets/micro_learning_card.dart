// ============================================================
// widgets/micro_learning_card.dart
// Full-screen micro-learning overlay triggered on high risk
// OSHC-aligned content
// ============================================================

import 'package:flutter/material.dart';
import '../models/posture_model.dart';
import '../services/alert_service.dart';

class MicroLearningCard extends StatefulWidget {
  final WorkerSector sector;
  final TaskType task;
  final bool cantonese;
  final VoidCallback onDismiss;

  const MicroLearningCard({
    super.key,
    required this.sector,
    required this.task,
    required this.cantonese,
    required this.onDismiss,
  });

  @override
  State<MicroLearningCard> createState() => _MicroLearningCardState();
}

class _MicroLearningCardState extends State<MicroLearningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late MicroTip _tip;

  @override
  void initState() {
    super.initState();
    final tips = MicroLearningTips.getTips(widget.sector, widget.task);
    _tip = tips.first;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black.withOpacity(0.92),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE74C3C), width: 2),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE74C3C),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.cantonese ? '安全提示' : 'Safety Tip',
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.cantonese ? _tip.titleZh : _tip.titleEn,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Content card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Icon(
                      IconData(_tip.iconCode, fontFamily: 'MaterialIcons'),
                      color: const Color(0xFF3498DB),
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.cantonese ? _tip.descZh : _tip.descEn,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.cantonese ? _tip.sourceZh : _tip.sourceEn,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dismiss
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.cantonese ? '明白了，繼續監測' : 'Got it, resume monitoring',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
