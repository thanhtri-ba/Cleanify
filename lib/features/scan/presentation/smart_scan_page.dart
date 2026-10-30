import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../application/scan_routing.dart';
import '../domain/scan_models.dart';
import 'widgets/category_meta.dart';

/// Màn quét (Figma 74:2432). Hiển thị tiến độ quét thật từ
/// [scanControllerProvider]; khi quét xong tự chuyển tới màn kết quả phù hợp.
class SmartScanPage extends ConsumerStatefulWidget {
  const SmartScanPage({super.key});

  @override
  ConsumerState<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends ConsumerState<SmartScanPage>
    with SingleTickerProviderStateMixin {
  /// Chu kỳ 12s; các vòng quay là bội số nguyên của chu kỳ nên lặp liền mạch.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    // Lượt quét có thể đã xong trước khi trang dựng xong.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handle(ref.read(scanControllerProvider));
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
    super.dispose();
  }

  void _handle(ScanState state) {
    if (_handled) return;
    final outcome = state.outcome;
    if (state.phase != ScanPhase.finished || outcome == null) return;
    _handled = true;
    final route = routeForOutcome(outcome);
    if (route == null) {
      context.canPop() ? context.pop() : context.go(AppRoutes.home);
    } else {
      context.pushReplacement(route);
    }
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
    final progress = scan.progress;
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final bottom = math.max(24.0, MediaQuery.viewPaddingOf(context).bottom);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stop();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            const _Glows(),
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
                          child: const AppSvg(
                            AppAssets.chevronLeft,
                            size: 18,
                            color: AppColors.titleInk,
                          ),
                        ),
                        Text(
                          AppStrings.smartScan,
                          style: AppText.custom(
                              20, FontWeight.w600, AppColors.titleInk,
                              lineHeight: 26, letterSpacing: -0.5),
                        ),
                        _RoundButton(
                          label: AppStrings.provisionalFindings,
                          onTap: _more,
                          child: const AppSvg(
                            AppAssets.moreHorizontal,
                            width: 14,
                            height: 4,
                            color: AppColors.titleInk,
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
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: _StatusText(loop: _loop),
                        ),
                        const SizedBox(height: 20),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: _StatsCard(progress: progress),
                        ),
                        const SizedBox(height: 14),
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
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                      stops: [0.55, 1],
                    ),
                  ),
                  child: Semantics(
                    button: true,
                    label: AppStrings.stopScan,
                    excludeSemantics: true,
                    child: Material(
                      color: AppColors.iconTile,
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
                                  14, FontWeight.w500, AppColors.titleInk,
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

class _Glows extends StatelessWidget {
  const _Glows();

  @override
  Widget build(BuildContext context) {
    Widget blob(Color color, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withAlpha(0)],
            ),
          ),
        );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -120,
            child: blob(const Color(0x66E5E7EB), 400),
          ),
          Positioned(
            left: -140,
            top: 220,
            child: blob(const Color(0xB3F3F4F6), 360),
          ),
          Positioned(
            right: -40,
            bottom: 60,
            child: blob(const Color(0x33E5E7EB), 300),
          ),
        ],
      ),
    );
  }
}

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
        color: AppColors.surface,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x66D1D5DB)),
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
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: loop,
              builder: (context, _) => CustomPaint(
                size: const Size(240, 240),
                painter: _ChamberPainter(loop.value),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, v, _) => CustomPaint(
              size: const Size(192, 192),
              painter: _ArcPainter(v),
            ),
          ),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x4DD1D5DB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E111827),
                  blurRadius: 36,
                  spreadRadius: -6,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x0F111827),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.iconTile,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: AppSvg(
                      AppAssets.scanTarget,
                      size: 14.67,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$percent',
                      style: AppText.custom(
                          44, FontWeight.w700, AppColors.titleInk,
                          lineHeight: 48, letterSpacing: -1.1),
                    ),
                    Text(
                      '%',
                      style: AppText.custom(
                          18, FontWeight.w600, AppColors.primary,
                          lineHeight: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Node {
  const _Node(this.deg, this.size, this.color, {this.glow = 0});

  final double deg;
  final double size;
  final Color color;
  final double glow;
}

class _ChamberPainter extends CustomPainter {
  const _ChamberPainter(this.t);

  /// 0..1 trong một chu kỳ 12s.
  final double t;

  static const _outerNodes = [
    _Node(-90, 10, Color(0xFF111827), glow: 8),
    _Node(0, 8, Color(0xFFD1D5DB), glow: 6),
    _Node(125, 6, Color(0xB34B5563)),
    _Node(35, 6, Color(0xCC6B7280), glow: 4),
    _Node(-150, 4, Color(0xFFD1D5DB)),
  ];
  static const _middleNodes = [
    _Node(90, 10, Color(0xFF111827), glow: 8),
    _Node(180, 6, Color(0xFFE5E7EB), glow: 6),
    _Node(-55, 6, Color(0xCC111827)),
    _Node(20, 4, Color(0xFF9CA3AF)),
  ];
  static const _dust = [
    (Offset(0.12, 0.30), 2.0, Color(0xFF9CA3AF)),
    (Offset(0.82, 0.10), 3.0, Color(0xFF6B7280)),
    (Offset(0.88, 0.78), 2.0, Color(0xFF9CA3AF)),
    (Offset(0.28, 0.86), 3.0, Color(0xFF111827)),
    (Offset(0.62, 0.92), 2.0, Color(0xFFD1D5DB)),
  ];

  void _node(Canvas canvas, Offset c, double r, double angle, _Node n) {
    final a = (n.deg * math.pi / 180) + angle;
    final p = c + Offset(math.cos(a), math.sin(a)) * r;
    if (n.glow > 0) {
      canvas.drawCircle(
        p,
        n.size / 2 + n.glow / 2,
        Paint()
          ..color = n.color.withAlpha(110)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, n.glow / 2),
      );
    }
    canvas.drawCircle(p, n.size / 2, Paint()..color = n.color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rect = Offset.zero & size;
    final tau = math.pi * 2;

    // Quầng ngoài.
    canvas.drawCircle(
      c,
      120,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.scanHaloTop, AppColors.scanHaloBottom],
        ).createShader(rect),
    );

    // Hạt bụi tĩnh.
    for (final (pos, r, color) in _dust) {
      canvas.drawCircle(Offset(pos.dx * size.width, pos.dy * size.height), r,
          Paint()..color = color);
    }

    // Vòng ngoài quay thuận.
    canvas.drawCircle(
      c,
      114,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66D1D5DB),
    );
    for (final n in _outerNodes) {
      _node(canvas, c, 114, t * tau, n);
    }

    // Vòng giữa nét đứt quay ngược.
    final dashRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x40111827);
    const dashCount = 64;
    final rotate = -t * tau;
    for (var i = 0; i < dashCount; i++) {
      final a0 = rotate + i * tau / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 100),
        a0,
        tau / dashCount * 0.5,
        false,
        dashRing,
      );
    }
    for (final n in _middleNodes) {
      _node(canvas, c, 100, rotate, n);
    }

    // Tia radar quét.
    final sweepRect = Rect.fromCircle(center: c, radius: 92);
    canvas.drawCircle(
      c,
      92,
      Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0x00111827),
            Color(0x00111827),
            Color(0x0D111827),
            Color(0x47111827),
          ],
          stops: const [0, 0.75, 0.847, 1],
          transform: GradientRotation(t * tau * 4),
        ).createShader(sweepRect),
    );

    // Vòng trong cùng.
    canvas.drawCircle(
      c,
      88,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x26111827),
    );
  }

  @override
  bool shouldRepaint(_ChamberPainter old) => old.t != t;
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0x8CE5E7EB),
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [Color(0xFF6B7280), Color(0xFF111827)],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.fraction != fraction;
}

// ───────────────────────── Trạng thái, thống kê, danh mục ─────────────────────────

class _StatusText extends StatelessWidget {
  const _StatusText({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        // Nhịp xung 1.5s, dấu chấm đổi mỗi 0.4s.
        final pulse = (loop.value * 8) % 1;
        final dots = (loop.value * 30).floor() % 3 + 1;
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (1 - pulse) * 0.75,
                        child: Transform.scale(
                          scale: 1 + pulse * 1.6,
                          child: const _Dot(10, AppColors.primary),
                        ),
                      ),
                      const _Dot(10, AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.scanningTitle,
                  style: AppText.custom(18, FontWeight.w600, AppColors.titleInk,
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
                  style: AppText.custom(
                      14, FontWeight.w400, AppColors.textSecondary,
                      lineHeight: 20),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 20,
                  child: Text(
                    '.' * dots,
                    style: AppText.custom(
                        14, FontWeight.w600, AppColors.primary,
                        lineHeight: 20, letterSpacing: 1.4),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

const _softShadow = [
  BoxShadow(
    color: Color(0x14111827),
    blurRadius: 30,
    spreadRadius: -4,
    offset: Offset(0, 10),
  ),
  BoxShadow(
    color: Color(0x0A191B27),
    blurRadius: 8,
    spreadRadius: -2,
    offset: Offset(0, 2),
  ),
];

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.progress});

  final ScanProgress progress;

  @override
  Widget build(BuildContext context) {
    Widget col(String value, String label,
        {bool accent = false, bool first = false}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            border: first
                ? null
                : const Border(left: BorderSide(color: Color(0x4DD1D5DB))),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppText.custom(
                    18,
                    accent ? FontWeight.w700 : FontWeight.w600,
                    accent ? AppColors.primary : AppColors.titleInk,
                    lineHeight: 24,
                    letterSpacing: -0.45),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.custom(
                    11, FontWeight.w600, AppColors.textSecondary,
                    lineHeight: 14, letterSpacing: 0.33),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x66D1D5DB)),
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
                style: AppText.custom(14, FontWeight.w600, AppColors.titleInk,
                    lineHeight: 20),
              ),
              Flexible(
                child: Text(
                  AppStrings.provisionalFindings,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.custom(11, FontWeight.w600, AppColors.textBlue,
                      lineHeight: 14, letterSpacing: 0.33),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66D1D5DB)),
            boxShadow: _softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, c) in ScanCategory.values.indexed) ...[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 1, color: Color(0x33D1D5DB)),
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.iconTile,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child:
                  AppSvg(category.icon, size: 16.67, color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: AppText.custom(14, FontWeight.w500, AppColors.titleInk,
                      lineHeight: 20),
                ),
                Text(
                  category.scanningHint(threshold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.custom(
                      11, FontWeight.w600, AppColors.textSecondary,
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
    final (text, fg, border, bg) = switch (status) {
      CategoryStatus.done => (
          AppStrings.doneStatus,
          AppColors.positive,
          AppColors.positiveSoft,
          const Color(0x1A65CDA9),
        ),
      CategoryStatus.pending => (
          AppStrings.pendingStatus,
          AppColors.textMuted,
          const Color(0x66D1D5DB),
          Colors.transparent,
        ),
      CategoryStatus.scanning => (
          AppStrings.scanningStatus,
          AppColors.titleInk,
          AppColors.titleInk,
          Colors.transparent,
        ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(6, fg),
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
