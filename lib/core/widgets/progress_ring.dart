import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Vòng tiến độ có nền và cung gradient. Không có animation vô hạn để
/// widget test không bị treo ở pumpAndSettle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.size,
    this.strokeWidth = 12,
    this.trackColor = const Color(0x1A625BEE),
    this.colors = const [AppColors.primary, AppColors.accent],
    this.child,
    this.semanticsLabel,
  });

  /// 0..1, ngoài khoảng sẽ được cắt.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> colors;
  final Widget? child;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: semanticsLabel,
      value: '${(value * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: value,
            strokeWidth: strokeWidth,
            trackColor: trackColor,
            colors: colors,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.colors,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (progress <= 0) return;
    final p = math.max(progress, 0.001);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [colors.first, colors.last, colors.last],
        stops: [0, p, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.colors != colors;
}
