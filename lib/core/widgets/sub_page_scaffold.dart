import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_svg.dart';
import 'fade_slide_in.dart';
import 'primary_button.dart';
import '../theme/app_tokens.dart';

/// Khung các màn phụ của Home: nút Back tròn, tiêu đề trái, nút phụ bên phải,
/// phần cuộn và thanh hành động đáy tuỳ chọn.
///
/// Dùng [SubPageScaffold.lazy] cho danh sách dài (dựng theo nhu cầu, tránh
/// tải hàng trăm ảnh thu nhỏ cùng lúc).
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.action,
    this.bottom,
    this.gap = 12,
  })  : itemCount = 0,
        itemBuilder = null;

  const SubPageScaffold.lazy({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    required this.itemCount,
    required this.itemBuilder,
    this.action,
    this.bottom,
    this.gap = 12,
  });

  final String title;
  final VoidCallback onBack;

  /// Phần đầu trang (hoặc toàn bộ nội dung với constructor thường).
  final List<Widget> children;
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final Widget? action;
  final Widget? bottom;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: AppStrings.back,
                      excludeSemantics: true,
                      child: Material(
                        color: context.tokens.surface,
                        shape: CircleBorder(
                          side: BorderSide(color: context.tokens.border),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBack,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: AppSvg(
                                AppAssets.chevronLeft,
                                size: 18,
                                color: context.tokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(
                            19, FontWeight.w700, context.tokens.textPrimary,
                            letterSpacing: -0.2),
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      16, 4, 16, itemBuilder == null ? 16 : 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      for (var i = 0; i < children.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                          child: FadeSlideIn(
                            delay: Duration(
                                milliseconds: 30 + math.min(i, 8) * 45),
                            child: children[i],
                          ),
                        ),
                    ]),
                  ),
                ),
                if (itemBuilder != null)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, gap, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                          child: itemBuilder!(context, i),
                        ),
                        childCount: itemCount,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// Thẻ trắng bo góc 20 có viền và bóng nhẹ.
class SubCard extends StatelessWidget {
  const SubCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: r,
        border: Border.all(color: context.tokens.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Nút nhỏ bo tròn ở góc phải thanh tiêu đề (Chọn tất cả, Đánh dấu đã đọc).
class SubPill extends StatelessWidget {
  const SubPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tokens.iconTile,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: AppText.custom(12.5, FontWeight.w600, context.tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm in hoa nhỏ ("HÔM NAY").
class SubSectionLabel extends StatelessWidget {
  const SubSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
      child: Text(
        text.toUpperCase(),
        style: AppText.custom(11, FontWeight.w600, context.tokens.textMuted,
            letterSpacing: 0.8),
      ),
    );
  }
}

/// Ghi chú nền nhạt viền đứt.
class SubHint extends StatelessWidget {
  const SubHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.tokens.border),
      ),
      child: Text(
        text,
        style: AppText.custom(12, FontWeight.w400, context.tokens.textMuted,
            lineHeight: 17),
      ),
    );
  }
}

/// Ô icon bo góc nền xám nhạt.
class SubIconTile extends StatelessWidget {
  const SubIconTile({
    super.key,
    required this.asset,
    this.size = 40,
    this.iconSize = 18,
    this.color,
    this.round = false,
  });

  final String asset;
  final double size;
  final double iconSize;
  final Color? color;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.tokens.iconTile,
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(12),
      ),
      child: Center(
          child: AppSvg(asset, size: iconSize, color: color ?? context.tokens.textPrimary)),
    );
  }
}

/// Số lớn kèm đơn vị nhỏ và chú thích bên dưới.
class SubBigStat extends StatelessWidget {
  const SubBigStat({
    super.key,
    required this.value,
    required this.unit,
    required this.caption,
  });

  final String value;
  final String unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppText.custom(34, FontWeight.w700, context.tokens.textPrimary,
                  lineHeight: 38, letterSpacing: -1),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: AppText.custom(14, FontWeight.w600, context.tokens.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: AppText.custom(12.5, FontWeight.w400, context.tokens.textMuted,
              lineHeight: 17),
        ),
      ],
    );
  }
}

/// Trạng thái rỗng giữa trang, tuỳ chọn có nút hành động.
class SubEmpty extends StatelessWidget {
  const SubEmpty({
    super.key,
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.tokens.iconTile,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: AppSvg(asset, size: 24, color: context.tokens.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.custom(16, FontWeight.w600, context.tokens.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppText.custom(13, FontWeight.w400, context.tokens.textMuted,
                lineHeight: 18),
          ),
        ],
      ),
    );
  }
}

/// Thanh hành động đáy với một nút chính; [onPressed] null = vô hiệu.
class SubBottomBar extends StatelessWidget {
  const SubBottomBar({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, math.max(12, inset)),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border(top: BorderSide(color: context.tokens.divider)),
      ),
      child: PrimaryButton(
        label: label,
        height: 52,
        shadows: const [],
        labelStyle: AppText.custom(15, FontWeight.w600, Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
