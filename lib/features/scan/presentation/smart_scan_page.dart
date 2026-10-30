import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../application/scan_routing.dart';
import '../domain/scan_models.dart';
import 'widgets/category_meta.dart';

/// Màn quét theo Figma node 127:1012. Hiển thị tiến độ quét thật từ
/// [scanControllerProvider]; khi quét xong tự chuyển tới màn kết quả phù hợp.
class SmartScanPage extends ConsumerStatefulWidget {
  const SmartScanPage({super.key});

  @override
  ConsumerState<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends ConsumerState<SmartScanPage>
    with SingleTickerProviderStateMixin {
  /// Chu kỳ 24s (chậm hơn để dễ theo dõi); các nhịp đều là bội số nguyên của chu kỳ nên lặp liền mạch.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _handled = false;

  /// Thanh tiến độ hiển thị chạy đủ 1 → 100% trong 15s, không phụ thuộc tốc độ quét thật.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  )
    ..addListener(() => setState(() {}))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _handle(ref.read(scanControllerProvider));
      }
    });

  @override
  void initState() {
    super.initState();
    // Lượt quét có thể đã xong trước khi trang dựng xong.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sweep.forward();
      _handle(ref.read(scanControllerProvider));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _sweep.dispose();
    super.dispose();
  }

  void _handle(ScanState state) {
    if (_handled) return;
    final outcome = state.outcome;
    if (state.phase != ScanPhase.finished || outcome == null) return;
    // Quét thật có thể xong sớm: vẫn chờ thanh 1→100% chạy hết. Người dùng tự dừng thì thoát ngay.
    if (outcome.end != ScanEnd.cancelled &&
        _sweep.status != AnimationStatus.completed) {
      return;
    }
    _handled = true;
    final route = routeForOutcome(outcome);
    if (route == null) {
      context.canPop() ? context.pop() : context.go(AppRoutes.home);
    } else {
      context.pushReplacement(route);
    }
  }

  /// Tiến độ hiển thị: số % chạy 1→100%, các hạng mục lần lượt xong theo cùng nhịp.
  ScanProgress _displayProgress(ScanProgress real) {
    final f = _sweep.value.clamp(0.0, 1.0);
    const n = ScanCategory.values.length;
    final statuses = <ScanCategory, CategoryStatus>{};
    for (final (i, c) in ScanCategory.values.indexed) {
      final start = i / n;
      final end = (i + 1) / n;
      statuses[c] = f >= end
          ? CategoryStatus.done
          : f >= start
              ? CategoryStatus.scanning
              : CategoryStatus.pending;
    }
    return ScanProgress(
      statuses: statuses,
      itemsChecked: real.itemsChecked,
      total: real.total,
      fraction: f < 0.01 ? 0.01 : f,
      estimatedBytes: real.estimatedBytes,
    );
  }

  void _stop() => ref.read(scanControllerProvider.notifier).cancel();

  void _more() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text(AppStrings.comingSoon),
        duration: Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScanState>(scanControllerProvider, (_, next) => _handle(next));
    final scan = ref.watch(scanControllerProvider);
    final progress = _displayProgress(scan.progress);
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final bottom = math.max(16.0, MediaQuery.viewPaddingOf(context).bottom);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stop();
      },
      child: Scaffold(
        backgroundColor: context.tokens.surface,
        body: Stack(
          children: [
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RoundButton(
                          label: AppStrings.back,
                          onTap: _stop,
                          child: AppSvg(
                            AppAssets.chevronLeft,
                            size: 18,
                            color: context.tokens.textPrimary,
                          ),
                        ),
                        Text(
                          AppStrings.smartScan,
                          style: AppText.custom(
                              20, FontWeight.w600, context.tokens.textPrimary,
                              lineHeight: 26, letterSpacing: -0.5),
                        ),
                        _RoundButton(
                          label: AppStrings.provisionalFindings,
                          onTap: _more,
                          child: AppSvg(
                            AppAssets.moreHorizontal,
                            width: 14,
                            height: 4,
                            color: context.tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Column(
                      children: [
                        FadeSlideIn(
                          child: _Chamber(
                            loop: _loop,
                            fraction: progress.fraction,
                            percent: progress.percent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 80),
                          child: _StatusText(),
                        ),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: _StatsCard(progress: progress),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: _CategoryList(
                            progress: progress,
                            threshold: threshold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: context.tokens.surface,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
                  child: Semantics(
                    button: true,
                    label: AppStrings.stopScan,
                    excludeSemantics: true,
                    child: Material(
                      color: context.tokens.iconTile,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _stop,
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              AppStrings.stopScan,
                              style: AppText.custom(
                                  14, FontWeight.w500, context.tokens.textPrimary,
                                  lineHeight: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _softShadow = [
  BoxShadow(
    color: Color(0x14676767),
    blurRadius: 30,
    spreadRadius: -4,
    offset: Offset(0, 10),
  ),
  BoxShadow(
    color: Color(0x0A1B1B1B),
    blurRadius: 8,
    spreadRadius: -2,
    offset: Offset(0, 2),
  ),
];

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.onTap,
    required this.label,
  });

  final Widget child;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: context.tokens.surface,
        shape: CircleBorder(
          side: BorderSide(color: context.tokens.borderSoft),
        ),
        elevation: 0.5,
        shadowColor: const Color(0x0D000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

// ───────────────────────── Buồng quét ─────────────────────────

/// Quả cầu nước neon (theo canvas): nước dâng theo tiến độ quét, vòng RGB, vạch quét và quỹ đạo xoay.
class _Chamber extends StatelessWidget {
  const _Chamber({
    required this.loop,
    required this.fraction,
    required this.percent,
  });

  final Animation<double> loop;
  final double fraction;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final numberStyle = AppText.custom(44, FontWeight.w700, Colors.white,
        lineHeight: 48, letterSpacing: -1.1).copyWith(
      shadows: const [Shadow(color: Color(0xAA38BDF8), blurRadius: 14)],
    );
    final unitStyle = AppText.custom(18, FontWeight.w600, Colors.white,
        lineHeight: 24);
    final labelStyle = AppText.custom(11, FontWeight.w600,
        const Color(0xFF9FD8F5),
        lineHeight: 14, letterSpacing: 1.1);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => RepaintBoundary(
              child: AnimatedBuilder(
                animation: loop,
                builder: (_, __) => CustomPaint(
                  size: const Size(240, 240),
                  painter: _OrbPainter(t: loop.value, fraction: v),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$percent', style: numberStyle),
                  Text('%', style: unitStyle),
                ],
              ),
              const SizedBox(height: 4),
              Text(AppStrings.scanningStatus.toUpperCase(),
                  style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.t, required this.fraction});

  /// 0..1, lấy từ vòng lặp 12s (mọi nhịp chạy số nguyên vòng nên lặp liền mạch).
  final double t;

  /// Tiến độ quét 0..1: càng cao thì nước càng dâng.
  final double fraction;

  static const _sphereR = 90.0;
  static const _ringR = 104.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final f = fraction.clamp(0.0, 1.0);
    final hue = (t * 360) % 360;
    final phase = t * math.pi * 2;
    Color rgb(double h, [double a = 1]) =>
        HSVColor.fromAHSV(a, h % 360, 0.85, 1).toColor();

    // Quầng sáng nền đổi màu theo hue.
    canvas.drawCircle(
      c,
      120,
      Paint()
        ..shader = RadialGradient(colors: [rgb(hue, 0.28), rgb(hue, 0)])
            .createShader(Rect.fromCircle(center: c, radius: 120)),
    );

    // Quỹ đạo chấm xoay chậm, có một hạt sáng.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(phase);
    final dotted = Paint()..color = const Color(0x4D7DD3FC);
    for (var i = 0; i < 48; i++) {
      final a = i * math.pi * 2 / 48;
      canvas.drawCircle(Offset(math.cos(a), math.sin(a)) * 118, 0.9, dotted);
    }
    canvas.drawCircle(const Offset(0, -118), 2.6, Paint()..color = rgb(hue));
    canvas.restore();

    // Vòng tiến độ: đường ray, phần đã quét (cầu vồng, có glow) và đầu sáng.
    final ringRect = Rect.fromCircle(center: c, radius: _ringR);
    canvas.drawCircle(
      c,
      _ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0x2294C5E6),
    );
    if (f > 0) {
      final sweep = math.pi * 2 * f;
      final shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 3 / 2,
        colors: [rgb(hue), rgb(hue + 120), rgb(hue + 240), rgb(hue)],
      ).createShader(ringRect);
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..shader = shader,
      );
      final a = -math.pi / 2 + sweep;
      final knob = c + Offset(math.cos(a), math.sin(a)) * _ringR;
      canvas.drawCircle(knob, 7,
          Paint()..color = const Color(0xFFE0FAFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(knob, 4.5, Paint()..color = const Color(0xFFFFFFFF));
    }

    // Quả cầu thủy tinh.
    final sphere = Rect.fromCircle(center: c, radius: _sphereR);
    canvas.drawCircle(
      c,
      _sphereR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xD917406F), Color(0xF206142B), Color(0xFF02060F)],
          stops: [0, 0.7, 1],
        ).createShader(sphere),
    );

    // Nước trong quả cầu, mực nước theo tiến độ.
    final level = c.dy + _sphereR - 2 * _sphereR * (0.2 + 0.8 * f);
    Path wave(double ph, double amp, double yOff, {required bool fill}) {
      final y0 = level + yOff;
      final left = c.dx - _sphereR - 10;
      final right = c.dx + _sphereR + 10;
      final p = Path()
        ..moveTo(left, y0 + math.sin((left - c.dx) / 28 + ph) * amp);
      for (var x = left + 4; x <= right; x += 4) {
        p.lineTo(x, y0 + math.sin((x - c.dx) / 28 + ph) * amp);
      }
      if (fill) {
        p
          ..lineTo(right, c.dy + _sphereR + 10)
          ..lineTo(left, c.dy + _sphereR + 10)
          ..close();
      }
      return p;
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    canvas.drawPath(wave(phase + 1.6, 5, 8, fill: true),
        Paint()..color = const Color(0x8C0284C7));
    canvas.drawPath(
      wave(phase, 6, 0, fill: true),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF03325C)],
        ).createShader(sphere),
    );
    canvas.drawPath(
      wave(phase, 6, 0, fill: false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xD9E0FAFF),
    );

    // Bọt nổi lên (2 nhịp mỗi vòng lặp).
    for (var i = 0; i < 4; i++) {
      final p = (t * 2 + i * 0.27) % 1.0;
      final bx = c.dx + math.sin(i * 2.1) * 50;
      final by = c.dy + _sphereR - 20 - p * 150;
      canvas.drawCircle(
        Offset(bx, by),
        2.5,
        Paint()..color = Color.fromRGBO(224, 247, 255, 0.7 * math.sin(math.pi * p)),
      );
    }

    // Vạch quét RGB chạy lên xuống qua quả cầu.
    final beamY = c.dy + math.sin(phase) * 70;
    final beamRect = Rect.fromLTWH(c.dx - 100, beamY - 14, 200, 28);
    canvas.drawRect(
      beamRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rgb(hue, 0), rgb(hue, 0.7), rgb(hue, 0)],
        ).createShader(beamRect),
    );
    canvas.restore();

    // Vòng nét đứt RGB xoay ngược chiều bên trong quả cầu.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-phase);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = rgb(hue, 0.6);
    const segments = 24;
    for (var i = 0; i < segments; i += 2) {
      final a0 = i * 2 * math.pi / segments;
      final a1 = (i + 1) * 2 * math.pi / segments;
      canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 78), a0, a1 - a0, false, dash);
    }
    canvas.restore();

    // Viền quả cầu đổi màu theo hue.
    canvas.drawCircle(
      c,
      _sphereR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = rgb(hue, 0.5),
    );

    // Phản quang kính.
    canvas.save();
    canvas.translate(c.dx - 30, c.dy - 42);
    canvas.rotate(-0.5);
    final gloss = Rect.fromCenter(center: Offset.zero, width: 84, height: 40);
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
        ).createShader(gloss),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t || old.fraction != fraction;
}

class _StatusText extends StatelessWidget {
  const _StatusText();

  /// Chấm xanh trạng thái đang quét, theo Figma (#009DE5).
  static const _pulse = Color(0xFF009DE5);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _pulse,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.scanningTitle,
              style: AppText.custom(18, FontWeight.w600, t.textPrimary,
                  lineHeight: 24, letterSpacing: -0.45),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.scanningSubtitle,
              style: AppText.custom(14, FontWeight.w400, t.textSecondary,
                  lineHeight: 20),
            ),
            const SizedBox(width: 6),
            Text(
              '...',
              style: AppText.custom(14, FontWeight.w600, t.textSecondary,
                  lineHeight: 20, letterSpacing: 1.4),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.progress});

  final ScanProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget col(String value, String label,
        {bool accent = false, bool first = false}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            border: first
                ? null
                : Border(left: BorderSide(color: t.borderSoft)),
          ),
          child: Column(
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.custom(
                    18,
                    accent ? FontWeight.w700 : FontWeight.w600,
                    accent ? t.textSecondary : t.textPrimary,
                    lineHeight: 24,
                    letterSpacing: -0.45),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.custom(11, FontWeight.w600, t.textSecondary,
                    lineHeight: 14, letterSpacing: 0.33),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderSoft),
        boxShadow: _softShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            col(formatCount(progress.itemsChecked), AppStrings.itemsChecked,
                first: true),
            col('${ScanCategory.values.length}', AppStrings.categories),
            col(formatBytes(progress.estimatedBytes), AppStrings.estimatedSpace,
                accent: true),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.progress, required this.threshold});

  final ScanProgress progress;
  final String threshold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.categoriesExamined,
                style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary,
                    lineHeight: 20),
              ),
              Flexible(
                child: Text(
                  AppStrings.provisionalFindings,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.custom(11, FontWeight.w600,
                      context.tokens.textMuted,
                      lineHeight: 14, letterSpacing: 0.33),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.tokens.borderSoft),
            boxShadow: _softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, c) in ScanCategory.values.indexed) ...[
                if (i > 0 && i != 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.tokens.divider,
                  ),
                _ScanRow(
                  category: c,
                  status: progress.statuses[c] ?? CategoryStatus.scanning,
                  threshold: threshold,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({
    required this.category,
    required this.status,
    required this.threshold,
  });

  final ScanCategory category;
  final CategoryStatus status;
  final String threshold;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.iconTile,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppSvg(category.icon, size: 17, color: t.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: AppText.custom(14, FontWeight.w500, t.textPrimary,
                      lineHeight: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  category.scanningHint(threshold),
                  style: AppText.custom(11, FontWeight.w600, t.textSecondary,
                      lineHeight: 14, letterSpacing: 0.33),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final CategoryStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (text, fg, border) = switch (status) {
      CategoryStatus.done => (AppStrings.doneStatus, t.success, t.textMuted),
      CategoryStatus.pending => (
          AppStrings.pendingStatus,
          t.textCaption,
          t.borderSoft,
        ),
      CategoryStatus.scanning => (
          AppStrings.scanningStatus,
          t.textPrimary,
          t.textPrimary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.custom(11, FontWeight.w600, fg,
                lineHeight: 14, letterSpacing: 0.33),
          ),
        ],
      ),
    );
  }
}
