import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum HeroMotion { none, float, sparkle, spin }

/// Một lớp ảnh trong suốt của minh hoạ (xuất từ bản thiết kế HTML).
class HeroLayer {
  const HeroLayer(
    this.asset, {
    this.motion = HeroMotion.none,
    this.period = 0,
    this.phase = 0,
  });

  final String asset;
  final HeroMotion motion;

  /// Chu kỳ lặp (giây).
  final double period;

  /// Độ lệch pha (giây), tương đương `animation-delay` âm trong CSS.
  final double phase;
}

/// Bộ lớp của từng minh hoạ. Mọi lớp cùng kích thước [designSize] nên chồng
/// khít lên nhau; chuyển động của từng lớp giống bản HTML của designer.
class HeroArtSpec {
  const HeroArtSpec({
    required this.designSize,
    required this.layers,
    this.spinAlignment = Alignment.center,
  });

  final double designSize;
  final List<HeroLayer> layers;

  /// Tâm quay của lớp [HeroMotion.spin].
  final Alignment spinAlignment;

  static const _p = 'assets/images/hero';

  static const art1 = HeroArtSpec(designSize: 310, layers: [
    HeroLayer('$_p/h1_base.png'),
    HeroLayer('$_p/h1_l00.png', motion: HeroMotion.float, period: 6.5, phase: 2.0),
    HeroLayer('$_p/h1_l01.png', motion: HeroMotion.float, period: 5.5, phase: 1.5),
    HeroLayer('$_p/h1_l02.png', motion: HeroMotion.float, period: 6.5, phase: 3.0),
    HeroLayer('$_p/h1_l03.png', motion: HeroMotion.float, period: 5.5, phase: 0.8),
    HeroLayer('$_p/h1_l04.png', motion: HeroMotion.float, period: 6.5, phase: 2.4),
    HeroLayer('$_p/h1_l05.png', motion: HeroMotion.float, period: 5.5, phase: 1.0),
    HeroLayer('$_p/h1_l06.png', motion: HeroMotion.sparkle, period: 3, phase: 0),
    HeroLayer('$_p/h1_l07.png', motion: HeroMotion.sparkle, period: 3, phase: 1.0),
    HeroLayer('$_p/h1_l08.png', motion: HeroMotion.sparkle, period: 3, phase: 2.0),
    HeroLayer('$_p/h1_l09.png', motion: HeroMotion.sparkle, period: 3, phase: 0.5),
    HeroLayer('$_p/h1_l10.png', motion: HeroMotion.sparkle, period: 3, phase: 1.5),
  ]);

  static const art2 = HeroArtSpec(designSize: 269, layers: [
    HeroLayer('$_p/h2_base.png'),
    HeroLayer('$_p/h2_l00.png', motion: HeroMotion.float, period: 6.5, phase: 2.0),
    HeroLayer('$_p/h2_l01.png', motion: HeroMotion.sparkle, period: 3, phase: 0),
    HeroLayer('$_p/h2_l02.png', motion: HeroMotion.sparkle, period: 3, phase: 1.0),
    HeroLayer('$_p/h2_l03.png', motion: HeroMotion.sparkle, period: 3, phase: 2.0),
    HeroLayer('$_p/h2_l04.png', motion: HeroMotion.sparkle, period: 3, phase: 0.6),
  ]);

  static const art3 = HeroArtSpec(
    designSize: 260,
    spinAlignment: Alignment(0, -2 / 130),
    layers: [
      HeroLayer('$_p/h3_base.png'),
      HeroLayer('$_p/h3_l00.png', motion: HeroMotion.spin, period: 24),
      HeroLayer('$_p/h3_l01.png', motion: HeroMotion.sparkle, period: 3, phase: 0.25),
      HeroLayer('$_p/h3_l02.png', motion: HeroMotion.sparkle, period: 3, phase: 1.25),
      HeroLayer('$_p/h3_l03.png', motion: HeroMotion.sparkle, period: 3, phase: 2.25),
      HeroLayer('$_p/h3_l04.png', motion: HeroMotion.sparkle, period: 3, phase: 0),
      HeroLayer('$_p/h3_l05.png', motion: HeroMotion.sparkle, period: 3, phase: 1.0),
      HeroLayer('$_p/h3_l06.png', motion: HeroMotion.sparkle, period: 3, phase: 2.0),
      HeroLayer('$_p/h3_l07.png', motion: HeroMotion.sparkle, period: 3, phase: 0.5),
    ],
  );
}

/// Minh hoạ nhiều lớp có chuyển động lặp: cả khối trôi nhẹ, thẻ nổi lên xuống,
/// sao lấp lánh, vòng bảo mật xoay chậm. Tự đứng yên khi hệ thống bật
/// "giảm chuyển động".
class HeroArt extends StatefulWidget {
  const HeroArt({super.key, required this.spec, required this.size});

  final HeroArtSpec spec;

  /// Cạnh vuông hiển thị (px logic).
  final double size;

  @override
  State<HeroArt> createState() => _HeroArtState();
}

class _HeroArtState extends State<HeroArt> with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _ticker.stop();
      _started = false;
    } else if (!_started) {
      _started = true;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0 mượt trong một chu kỳ (giống ease-in-out của CSS).
  static double _wave(double t, double period, double phase) {
    final u = ((t + phase) % period) / period;
    return (1 - math.cos(2 * math.pi * u)) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.size / widget.spec.designSize;
    final spec = widget.spec;
    final layers = <Widget>[
      for (final l in spec.layers)
        _buildLayer(l, k),
    ];
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ValueListenableBuilder<double>(
        valueListenable: _time,
        child: Stack(fit: StackFit.expand, children: layers),
        // Cả khối trôi lên xuống 7px như `.float` của bản HTML.
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, -7 * k * _wave(t, 5.5, 0)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLayer(HeroLayer l, double k) {
    final image = Image.asset(
      l.asset,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    if (l.motion == HeroMotion.none) return Positioned.fill(child: image);
    return Positioned.fill(
      child: ValueListenableBuilder<double>(
        valueListenable: _time,
        child: image,
        builder: (context, t, child) {
          switch (l.motion) {
            case HeroMotion.float:
              return Transform.translate(
                offset: Offset(0, -7 * k * _wave(t, l.period, l.phase)),
                child: child,
              );
            case HeroMotion.sparkle:
              return Opacity(
                opacity: 0.35 + 0.65 * _wave(t, l.period, l.phase),
                child: child,
              );
            case HeroMotion.spin:
              return Transform.rotate(
                angle: 2 * math.pi * (((t + l.phase) % l.period) / l.period),
                alignment: widget.spec.spinAlignment,
                child: child,
              );
            case HeroMotion.none:
              return child!;
          }
        },
      ),
    );
  }
}
