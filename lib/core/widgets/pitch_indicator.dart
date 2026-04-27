import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/music_constants.dart';

/// Circular ring with a tick that swings between -50 and +50 cents.
/// A subtle inner glow appears when [stable] is true.
class PitchRing extends StatelessWidget {
  final double cents;
  final bool voiced;
  final bool stable;
  final double size;
  final Widget? center;

  const PitchRing({
    super.key,
    required this.cents,
    required this.voiced,
    required this.stable,
    required this.size,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: CustomPaint(
          key: ValueKey('$voiced-$stable'),
          painter: _PitchRingPainter(
            cents: cents,
            voiced: voiced,
            stable: stable,
          ),
          child: Center(child: center ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

class _PitchRingPainter extends CustomPainter {
  final double cents;
  final bool voiced;
  final bool stable;

  _PitchRingPainter({
    required this.cents,
    required this.voiced,
    required this.stable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;

    final basePaint = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, basePaint);

    // Tick marks every 25 cents.
    final tickPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5;
    for (var c = -50; c <= 50; c += 25) {
      final t = c / 50.0;
      final angle = -math.pi / 2 + t * (math.pi * 0.5);
      final p1 = Offset(
        center.dx + math.cos(angle) * (radius - 6),
        center.dy + math.sin(angle) * (radius - 6),
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * (radius + 6),
        center.dy + math.sin(angle) * (radius + 6),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    if (!voiced) return;

    final clamped = cents.clamp(-50.0, 50.0);
    final t = clamped / 50.0;
    final angle = -math.pi / 2 + t * (math.pi * 0.5);

    final color = _accuracyColor(clamped);

    if (stable) {
      final glow = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, radius, glow);
    }

    // Arc from -90 (top) sweeping toward the tick.
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final startAngle = -math.pi / 2;
    final sweep = t * (math.pi * 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      arcPaint,
    );

    // Tip dot.
    final tip = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final tipPaint = Paint()..color = color;
    canvas.drawCircle(tip, 6, tipPaint);
  }

  Color _accuracyColor(double cents) {
    final abs = cents.abs();
    if (abs <= MusicConstants.inTuneCents) return AppColors.inTune;
    if (abs <= MusicConstants.slightlyOffCents) return AppColors.slightlyOff;
    return AppColors.offPitch;
  }

  @override
  bool shouldRepaint(covariant _PitchRingPainter old) =>
      old.cents != cents || old.voiced != voiced || old.stable != stable;
}
