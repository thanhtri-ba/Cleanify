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
import '../application/cleanup_controller.dart';

/// Cleaning theo Figma node 127:1322. Logic tiến độ xóa thật giữ nguyên:
/// xong thì sang Cleanup Complete, bị từ chối/lỗi thì về Review.
class CleaningPage extends ConsumerStatefulWidget {
  const CleaningPage({super.key});

  @override
  ConsumerState<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends ConsumerState<CleaningPage> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handle(ref.read(cleanupControllerProvider));
    });
  }

  void _handle(CleanupState s) {
    if (_handled || s.phase != CleanupPhase.finished) return;
    final o = s.outcome;
    if (o == null) return;
    _handled = true;
    if (o.declined) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text(AppStrings.deletionNotConfirmed)));
      context.pushReplacement(AppRoutes.cleanupReview);
    } else {
      context.pushReplacement(AppRoutes.cleanupComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CleanupState>(cleanupControllerProvider, (_, n) => _handle(n));
    final s = ref.watch(cleanupControllerProvider);
    final waiting = s.fraction == 0 && s.phase == CleanupPhase.running;
    final canPause = !(s.pausing || s.phase != CleanupPhase.running);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.tokens.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Material(
                          color: context.tokens.surfaceMuted,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: canPause
                                ? () => ref
                                    .read(cleanupControllerProvider.notifier)
                                    .pause()
                                : null,
                            child: Center(
                              child: AppSvg(
                                AppAssets.chevronLeft,
                                size: 14,
                                color: context.tokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.cleaningStorage,
                          textAlign: TextAlign.center,
                          style: AppText.custom(
                              18, FontWeight.w600, context.tokens.textPrimary,
                              lineHeight: 24, letterSpacing: -0.45),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Center(child: _Ring(fraction: s.fraction, percent: s.percent)),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.makingRoom,
                      textAlign: TextAlign.center,
                      style: AppText.custom(24, FontWeight.w600, context.tokens.textPrimary,
                          lineHeight: 30, letterSpacing: -0.6),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB4B4B4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            waiting
                                ? AppStrings.waitingConfirmation
                                : AppStrings.processingConfirmed,
                            textAlign: TextAlign.center,
                            style: AppText.custom(
                                14, FontWeight.w400, context.tokens.textSecondary,
                                lineHeight: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 17),
                      decoration: BoxDecoration(
                        color: context.tokens.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x59C6C6C6)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Stat(
                              value: formatBytes(s.processedBytes),
                              label: AppStrings.mediaProcessed,
                              valueColor: context.tokens.textSecondary,
                            ),
                            _Stat(
                              value: formatCount(s.selectedCount),
                              label: AppStrings.itemsSelected,
                              divider: true,
                            ),
                            _Stat(
                              value: formatBytes(s.remainingBytes),
                              label: AppStrings.remaining,
                              divider: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.cleaningProgress,
                          style: AppText.custom(
                              14, FontWeight.w500, context.tokens.textSecondary,
                              lineHeight: 20),
                        ),
                        Text(
                          '${s.percent}%',
                          style: AppText.custom(
                              14, FontWeight.w600, context.tokens.textPrimary,
                              lineHeight: 18, letterSpacing: 0.14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _GradientBar(fraction: s.fraction.clamp(0.0, 1.0)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Material(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: canPause
                        ? () => ref
                            .read(cleanupControllerProvider.notifier)
                            .pause()
                        : null,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x66C6C6C6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppSvg(
                            AppAssets.layers,
                            size: 16,
                            color: canPause
                                ? context.tokens.textPrimary
                                : context.tokens.textCaption,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.pausing
                                ? AppStrings.pausing
                                : AppStrings.pauseCleanup,
                            style: AppText.custom(
                                14, FontWeight.w500, context.tokens.textPrimary,
                                lineHeight: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hiệu ứng hút rác: các mảnh file bị kéo từ rìa màn vào tâm xoáy, vòng tiến độ ở ngoài, số phần trăm ở giữa.
class _Ring extends StatefulWidget {
  const _Ring({required this.fraction, required this.percent});

  final double fraction;
  final int percent;

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  // 6 giây một vòng; các hạt quay số vòng nguyên nên lặp liền mạch.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => CustomPaint(
                  size: const Size(280, 280),
                  painter: _VortexPainter(
                    t: _loop.value,
                    fraction: v,
                    ink: t.textPrimary,
                    muted: t.textMuted,
                    track: t.chip,
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.percent}%',
                style: AppText.custom(44, FontWeight.w700, t.textPrimary,
                    lineHeight: 48, letterSpacing: -1.1),
              ),
              const SizedBox(height: 4),
              Text(
                'IN PROGRESS',
                style: AppText.custom(11, FontWeight.w600, t.textSecondary,
                    lineHeight: 14, letterSpacing: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VortexPainter extends CustomPainter {
  const _VortexPainter({
    required this.t,
    required this.fraction,
    required this.ink,
    required this.muted,
    required this.track,
  });

  /// 0..1, lấy từ vòng lặp 6 giây.
  final double t;

  /// Tiến độ dọn 0..1: càng nhiều thì càng nhiều hạt được hút.
  final double fraction;
  final Color ink;
  final Color muted;
  final Color track;

  static const _count = 26;
  static const _ringR = 116.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final f = fraction.clamp(0.0, 1.0);

    // Lõi xoáy tối nhẹ ở giữa.
    canvas.drawCircle(
      c,
      100,
      Paint()
        ..shader = RadialGradient(
          colors: [ink.withValues(alpha: 0.08), ink.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: c, radius: 100)),
    );

    // Ba nhánh xoáy quay dần vào tâm.
    final arm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = muted.withValues(alpha: 0.28);
    for (var k = 0; k < 3; k++) {
      final path = Path();
      for (var j = 0; j <= 40; j++) {
        final u = j / 40;
        final ang = u * math.pi * 2 * 1.1 + k * math.pi * 2 / 3 + t * math.pi * 2;
        final r = 200 - 96 * math.pow(u, 1.4).toDouble();
        final pt = c + Offset(math.cos(ang), math.sin(ang)) * r;
        if (j == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, arm);
    }

    // Vòng tiến độ: nền + phần đã dọn.
    const stroke = 10.0;
    final rect = Rect.fromCircle(center: c, radius: _ringR);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (f > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * f,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = ink,
      );
    }

    // Các mảnh file bị hút vào tâm.
    final active = (_count * (0.35 + 0.65 * f)).round();
    final tile = Paint();
    final trail = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < active; i++) {
      final seed = (i * 0.618034) % 1.0;
      // Số vòng trong 6 giây là số nguyên để vòng lặp liền mạch.
      final speed = i % 3 == 0 ? 2 : 3;
      final p = (t * speed + seed) % 1.0;
      final alpha = math.pow(math.sin(math.pi * p), 0.6).toDouble() * 0.9;
      final pos = _pos(i, p, c);
      final dia = 3.0 + 5.0 * (1 - p * p);

      final prevP = p - 0.07;
      if (prevP > 0) {
        trail
          ..strokeWidth = dia * 0.6
          ..color = muted.withValues(alpha: alpha * 0.3);
        canvas.drawLine(_pos(i, prevP, c), pos, trail);
      }

      tile.color = (i % 3 == 0 ? ink : muted).withValues(alpha: alpha);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(i * 0.7 + p * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: dia, height: dia),
          Radius.circular(dia * 0.3),
        ),
        tile,
      );
      canvas.restore();
    }
  }

  /// Vị trí hạt [i] ở pha [p]: bắt đầu ngoài khung, xoáy và tăng tốc vào vòng tiến độ.
  Offset _pos(int i, double p, Offset c) {
    final e = p * p;
    final r = 210 - 94 * e;
    final ang = i * 2.39996 + e * 1.6;
    return c + Offset(math.cos(ang), math.sin(ang)) * r;
  }

  @override
  bool shouldRepaint(_VortexPainter old) =>
      old.t != t ||
      old.fraction != fraction ||
      old.ink != ink ||
      old.muted != muted ||
      old.track != track;
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.valueColor,
    this.divider = false,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: divider
              ? const Border(left: BorderSide(color: Color(0x4DC6C6C6)))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppText.custom(20, FontWeight.w600, valueColor ?? context.tokens.textPrimary,
                  lineHeight: 26, letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.custom(
                  12, FontWeight.w500, context.tokens.textSecondary,
                  lineHeight: 16, letterSpacing: 0.12),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientBar extends StatelessWidget {
  const _GradientBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: context.tokens.iconTile,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: box.maxWidth * fraction,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9999),
              gradient: const LinearGradient(
                colors: [Color(0xFF17EB41), Color(0xFF4C4C4C)],
                stops: [0, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
