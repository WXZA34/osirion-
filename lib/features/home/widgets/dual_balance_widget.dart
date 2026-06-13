import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arc_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/arc_provider.dart';

class DualBalanceWidget extends ConsumerWidget {
  final double forcePercentage; // 0.0 to 1.0
  final double wisdomPercentage; // 0.0 to 1.0
  final Color forceColor;
  final Color wisdomColor;
  final String wisdomLabel;

  const DualBalanceWidget({
    super.key,
    required this.forcePercentage,
    required this.wisdomPercentage,
    required this.forceColor,
    required this.wisdomColor,
    this.wisdomLabel = "SAGESSE",
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arc = ref.watch(arcProvider);
    final bool isSummer = arc.arcType == AlphaArc.summer;
    return SizedBox(
      width: double.infinity,
      height: 130, // Hauteur du widget de balance (augmentée pour éviter l'overflow de 2px)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Demi-cercle FORCE (Gauche)
          _buildHalfCircle(
            label: "FORCE",
            percentage: forcePercentage,
            color: forceColor,
            isLeft: true,
            icon: Icons.fitness_center,
            isSummer: isSummer,
          ),

          // Séparateur central
          Container(width: 1, height: 60, color: isSummer ? Colors.black12 : Colors.white12),

          // Demi-cercle SAGESSE (Droite)
          _buildHalfCircle(
            label: wisdomLabel,
            percentage: wisdomPercentage,
            color: wisdomColor,
            isLeft: false,
            icon: Icons.self_improvement,
            isSummer: isSummer,
          ),
        ],
      ),
    );
  }

  Widget _buildHalfCircle({
    required String label,
    required double percentage,
    required Color color,
    required bool isLeft,
    required IconData icon,
    required bool isSummer,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(80, 80),
                painter: _HalfCirclePainter(
                  percentage: percentage,
                  color: color,
                  isLeft: isLeft,
                  isSummer: isSummer,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.8), size: 24),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSummer ? Colors.black45 : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "${(percentage * 100).toInt()}",
                style: TextStyle(
                  color: isSummer ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: " %",
                style: TextStyle(
                  color: isSummer ? Colors.black45 : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final bool isLeft;
  final bool isSummer;

  _HalfCirclePainter({
    required this.percentage,
    required this.color,
    required this.isLeft,
    required this.isSummer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        min(size.width / 2, size.height / 2) - 4; // -4 for stroke width

    // Background Arc (Empty)
    final bgPaint =
        Paint()
          ..color = isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Foreground Arc (Filled)
    final fgPaint =
        Paint()
          ..color = color
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Shadow for Foreground
    final shadowPaint =
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Angles:
    // Left semi-circle: roughly from top (PI/2) to bottom (-PI/2) on the left side
    // Right semi-circle: roughly from top (PI/2) to bottom (-PI/2) on the right side

    // Flutter angle system: 0 is 3 o'clock, PI/2 is 6 o'clock, PI is 9 o'clock.
    final startAngle = isLeft ? pi / 2 : -pi / 2;
    final sweepAngleBase = pi; // Half circle

    // Draw background
    canvas.drawArc(rect, startAngle, sweepAngleBase, false, bgPaint);

    // Draw foreground based on percentage
    final sweepAngleActive = sweepAngleBase * percentage;

    if (percentage > 0) {
      canvas.drawArc(rect, startAngle, sweepAngleActive, false, shadowPaint);
      canvas.drawArc(rect, startAngle, sweepAngleActive, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HalfCirclePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
