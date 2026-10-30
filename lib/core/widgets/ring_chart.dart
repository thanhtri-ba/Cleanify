import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class RingSegment {
  const RingSegment(this.value, this.color);

  final double value;
  final Color color;
}

/// Biểu đồ vòng (donut) nhiều đoạn, vẽ dần khi xuất hiện.
/// Nếu [total] null thì tổng các đoạn là cả vòng; nếu có [total] thì phần
/// còn lại hiện màu nền [trackColor].
class RingChart extends StatelessWidget {
  const RingChart({
    super.key,
    required this.segments,
    this.total,
    this.size = 128,
    this.strokeWidth = 16,
    this.center,
    this.trackColor,
  });

  final List<RingSegment> segments;
  final double? total;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            segments: segments,
            total: total,
            strokeWidth: strokeWidth,
            trackColor: trackColor ?? context.tokens.chip,
            progress: t,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.trackColor,
    required this.progress,
  });

  final List<RingSegment> segments;
  final double? total;
  final double strokeWidth;
  final Color trackColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final sum = segments.fold<double>(0, (s, e) => s + e.value);
    final denom = total ?? sum;
    if (denom <= 0) return;

    const gap = 0.04; // radian giữa hai đoạn
    var start = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = seg.value / denom * math.pi * 2 * progress;
      final draw = segments.length > 1 ? math.max(0.0, sweep - gap) : sweep;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = segments.length > 1 ? StrokeCap.butt : StrokeCap.round
        ..color = seg.color;
      canvas.drawArc(rect, start, draw, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.total != total ||
      old.strokeWidth != strokeWidth ||
      old.segments != segments;
}
