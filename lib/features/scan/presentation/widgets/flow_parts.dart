import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_svg.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/scan_models.dart';
import 'category_meta.dart';

/// Các thành phần dùng chung cho luồng quét → xem lại → dọn dẹp.

/// Gói danh sách widget thành các khối hiện lần lượt.
List<Widget> staggered(List<Widget> items, {int startMs = 40, int stepMs = 60}) {
  return [
    for (var i = 0; i < items.length; i++)
      FadeSlideIn(
        delay: Duration(milliseconds: startMs + i * stepMs),
        child: items[i],
      ),
  ];
}

/// Thanh tiêu đề: nút Back tròn, tiêu đề giữa, chỗ trống cân đối.
class FlowNavBar extends StatelessWidget {
  const FlowNavBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: onBack == null
                    ? null
                    : Semantics(
                        button: true,
                        label: AppStrings.back,
                        excludeSemantics: true,
                        child: Material(
                          color: AppColors.iconTile,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onBack,
                            child: const Center(
                              child: AppSvg(
                                AppAssets.chevronLeft,
                                size: 18,
                                color: AppColors.titleInk,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              Text(
                title,
                style: AppText.custom(18, FontWeight.w600, AppColors.titleInk),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung trang: nền trắng, thanh tiêu đề, phần cuộn và thanh hành động đáy.
class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
    this.gap = 16,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          FlowNavBar(title: title, onBack: onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// Thanh hành động đáy: viền trên mảnh, nút xếp dọc, chừa vùng an toàn.
class FlowActionBar extends StatelessWidget {
  const FlowActionBar({super.key, required this.children, this.topBorder});

  final List<Widget> children;
  final Color? topBorder;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, math.max(8, inset)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: topBorder ?? AppColors.footerBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Nút chính 52px của các màn kết quả.
class FlowPrimaryButton extends StatelessWidget {
  const FlowPrimaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      height: 52,
      shadows: const [],
      labelStyle: AppText.custom(14, FontWeight.w600, Colors.white),
      onPressed: onPressed,
    );
  }
}

/// Nút phụ 52px viền nhạt, chữ màu accent.
class FlowSecondaryButton extends StatelessWidget {
  const FlowSecondaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: label,
      height: 52,
      borderColor: AppColors.divider2,
      labelStyle: AppText.custom(14, FontWeight.w600, AppColors.accent),
      onPressed: onPressed,
    );
  }
}

/// Khối thông tin nền nhạt (What happens next, Need to recover...).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.custom(13, FontWeight.w600, AppColors.titleInk,
                lineHeight: 18),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.custom(12, FontWeight.w400, AppColors.textSecondary,
                lineHeight: 18),
          ),
        ],
      ),
    );
  }
}

/// Số dung lượng đếm tăng dần từ 0 tới [bytes], hiển thị bằng [builder].
class CountUpBytes extends StatelessWidget {
  const CountUpBytes({
    super.key,
    required this.bytes,
    required this.builder,
    this.duration = const Duration(milliseconds: 1000),
  });

  final int bytes;
  final Duration duration;
  final Widget Function(BuildContext context, int bytes) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: bytes.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}

/// Khung danh sách bo góc 22 có đường kẻ ngăn giữa các dòng.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.children,
    this.color = AppColors.surface,
    this.bordered = true,
    this.shadow = false,
    this.radius = 22,
  });

  final List<Widget> children;
  final Color color;
  final bool bordered;
  final bool shadow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: AppColors.divider2) : null,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0 && bordered)
              const Divider(height: 1, thickness: 1, color: AppColors.divider2),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Dòng danh mục: icon tròn, tên, mô tả ngắn và phần phải tuỳ ý.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.trailing,
    this.hint,
    this.height = 48,
    this.tile = 30,
    this.onTap,
    this.titleMuted = false,
  });

  final ScanCategory category;
  final Widget trailing;
  final String? hint;
  final double height;
  final double tile;
  final VoidCallback? onTap;
  final bool titleMuted;

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: tile,
              height: tile,
              decoration: const BoxDecoration(
                color: AppColors.categoryTile,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppSvg(
                  category.icon,
                  size: tile * 0.46,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.custom(14, FontWeight.w500,
                        AppColors.titleInk,
                        lineHeight: 20),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(
                          11, FontWeight.w400, AppColors.textMuted,
                          lineHeight: 15),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Giá trị bên phải dòng danh mục (vd. "640 MB").
class RowValue extends StatelessWidget {
  const RowValue(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: muted
          ? AppText.custom(12, FontWeight.w500, AppColors.textMuted)
          : AppText.custom(14, FontWeight.w500, AppColors.titleInk),
    );
  }
}

/// Vòng tròn chọn: đã chọn = nền primary + dấu tick.
class SelectCheck extends StatelessWidget {
  const SelectCheck({super.key, required this.selected, this.size = 24});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.cardBorderSoft,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: selected ? 1 : 0,
          child: AppSvg(AppAssets.check, size: size * 0.5, color: Colors.white),
        ),
      ),
    );
  }
}

/// Huy hiệu trạng thái 64px: dấu tick tự vẽ và vòng sóng lan ra.
class StateBadge extends StatefulWidget {
  const StateBadge({super.key});

  @override
  State<StateBadge> createState() => _StateBadgeState();
}

class _StateBadgeState extends State<StateBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _ripple.stop();
    } else if (!_ripple.isAnimating) {
      _ripple.repeat();
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _ripple,
            builder: (context, _) => CustomPaint(
              size: const Size(64, 64),
              painter: _RipplePainter(_ripple.value),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider2),
            ),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, s, child) =>
                    Transform.scale(scale: s, child: child),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider2),
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: const Interval(0.35, 1, curve: Curves.easeOut),
                      builder: (context, t, _) => CustomPaint(
                        size: const Size(26, 26),
                        painter: _CheckPainter(t),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(5 * s, 12.5 * s)
      ..lineTo(9.5 * s, 17 * s)
      ..lineTo(19 * s, 7.5 * s);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.primary;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t.clamp(0.0, 1.0)), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final phase in const [0.0, 0.5]) {
      final p = (t + phase) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.fromARGB((90 * (1 - p)).round(), 17, 24, 39);
      canvas.drawCircle(c, size.width / 2 * (1 + 0.9 * p), paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}
