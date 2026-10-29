import 'package:flutter/material.dart';

/// Hiện dần và trượt lên một lần khi widget xuất hiện. Không lặp nên
/// `pumpAndSettle` trong test vẫn kết thúc; tự tắt khi hệ thống bật
/// "giảm chuyển động".
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.dy = 14,
    this.scaleFrom = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Quãng trượt ban đầu theo chiều dọc (px).
  final double dy;

  /// Tỉ lệ ban đầu; 1 = không phóng to/thu nhỏ.
  final double scaleFrom;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: const Cubic(0.22, 1, 0.36, 1),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        Widget content = child!;
        if (widget.scaleFrom != 1) {
          content = Transform.scale(
            scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
            child: content,
          );
        }
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.dy),
            child: content,
          ),
        );
      },
    );
  }
}
