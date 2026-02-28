// ============================================================
// widgets/angle_bars.dart
// Horizontal bars showing key joint angles in real time
// ============================================================

import 'package:flutter/material.dart';

class AngleBars extends StatelessWidget {
  final double neckAngle;
  final double trunkAngle;
  final double leftShoulderAngle;
  final double rightShoulderAngle;
  final bool cantonese;

  const AngleBars({
    super.key,
    required this.neckAngle,
    required this.trunkAngle,
    required this.leftShoulderAngle,
    required this.rightShoulderAngle,
    required this.cantonese,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AngleBar(
          label: cantonese ? '頸部' : 'Neck',
          angle: neckAngle,
          maxSafe: 20,
          maxAngle: 60,
        ),
        const SizedBox(height: 6),
        _AngleBar(
          label: cantonese ? '腰背' : 'Trunk',
          angle: trunkAngle,
          maxSafe: 20,
          maxAngle: 60,
        ),
        const SizedBox(height: 6),
        _AngleBar(
          label: cantonese ? '左肩' : 'L.Arm',
          angle: leftShoulderAngle,
          maxSafe: 45,
          maxAngle: 120,
        ),
        const SizedBox(height: 6),
        _AngleBar(
          label: cantonese ? '右肩' : 'R.Arm',
          angle: rightShoulderAngle,
          maxSafe: 45,
          maxAngle: 120,
        ),
      ],
    );
  }
}

class _AngleBar extends StatelessWidget {
  final String label;
  final double angle;
  final double maxSafe;
  final double maxAngle;

  const _AngleBar({
    required this.label,
    required this.angle,
    required this.maxSafe,
    required this.maxAngle,
  });

  Color get _barColor {
    final a = angle.abs();
    if (a <= maxSafe) return const Color(0xFF27AE60);
    if (a <= maxSafe * 1.5) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (angle.abs() / maxAngle).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Safe zone marker
              Positioned(
                left: (maxSafe / maxAngle) *
                    (MediaQuery.of(context).size.width - 100),
                child: Container(
                  width: 2,
                  height: 8,
                  color: Colors.white38,
                ),
              ),
              // Progress bar
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${angle.abs().toStringAsFixed(0)}°',
            style: TextStyle(color: _barColor, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
