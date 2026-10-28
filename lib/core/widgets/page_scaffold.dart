import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_svg.dart';

/// Nút Back tròn nền nhạt dùng ở header các màn con.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.back,
      excludeSemantics: true,
      child: Material(
        color: AppColors.iconTile,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Center(child: AppSvg(AppAssets.chevronLeft, size: 18)),
          ),
        ),
      ),
    );
  }
}

/// Khung chung cho màn con: header (Back + tiêu đề giữa), đường kẻ, nội dung
/// cuộn được và [footer].
///
/// - Mặc định [footer] nằm trong vùng cuộn và dính đáy khi nội dung ngắn.
/// - Với [stickyFooter] = true, footer luôn cố định dưới màn, có viền trên.
/// - Nút Back chỉ hiện khi có thể quay lại (hoặc truyền [onBack]);
///   [showBack] = false để ẩn hẳn (ví dụ khi đang xử lý, không cho thoát).
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.onBack,
    this.showBack = true,
    this.stickyFooter = false,
    this.horizontalPadding = 24,
    this.gap = 20,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;
  final VoidCallback? onBack;
  final bool showBack;
  final bool stickyFooter;
  final double horizontalPadding;
  final double gap;

  static const double _padTop = 24;
  static const double _padBottom = 30;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final VoidCallback? back = !showBack
        ? null
        : onBack ??
            ((router?.canPop() ?? false) ? () => router!.pop() : null);

    final footerWidget = footer;
    final inlineFooter = footerWidget != null && !stickyFooter;
    final padTop = stickyFooter ? 16.0 : _padTop;
    final padBottom = stickyFooter ? 16.0 : _padBottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Row(
                  children: [
                    if (back != null)
                      CircleBackButton(onPressed: back)
                    else
                      const SizedBox(width: 36),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: AppText.pageTitle,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
            if (!stickyFooter)
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      padTop,
                      horizontalPadding,
                      padBottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          constraints.maxHeight - padTop - padBottom,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < children.length; i++) ...[
                              if (i > 0) SizedBox(height: gap),
                              children[i],
                            ],
                            if (inlineFooter) ...[
                              const Spacer(),
                              SizedBox(height: gap),
                              footerWidget,
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (stickyFooter && footerWidget != null)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.footerBorder),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: footerWidget,
              ),
          ],
        ),
      ),
    );
  }
}
