import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/platform_copy.dart';
import '../application/cleanup_controller.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import 'widgets/category_meta.dart';
import 'widgets/flow_parts.dart';
import 'widgets/result_buttons.dart';

/// Review Cleanup theo Figma 127:3229: xác nhận lần cuối trước khi hệ điều
/// hành hỏi xóa. Logic chọn và bắt đầu dọn dẹp giữ nguyên.
class ReviewCleanupPage extends ConsumerWidget {
  const ReviewCleanupPage({super.key});

  static const _keepHint = 'Want to keep something?';
  static const _continueLabel = 'Continue';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(cleanupPlanProvider);
    if (plan == null) {
      return FlowScaffold(
        title: AppStrings.reviewCleanup,
        onBack: () => context.pop(),
        children: const [SizedBox.shrink()],
      );
    }
    final ios = isIosPlatform;
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final cats = plan.selectedCategories.toList();
    final canContinue = !plan.isEmpty;

    return FlowScaffold(
      title: AppStrings.reviewCleanup,
      onBack: () => context.pop(),
      bottom: FlowActionBar(
        topBorder: context.tokens.border,
        children: [
          Text(
            ios ? AppStrings.nextConfirmIos : AppStrings.nextConfirmAndroid,
            textAlign: TextAlign.center,
            style: AppText.custom(12, FontWeight.w400, context.tokens.textCaption,
                lineHeight: 16),
          ),
          ResultPrimaryButton(
            label: _continueLabel,
            onPressed: canContinue
                ? () {
                    ref.read(cleanupControllerProvider.notifier).start();
                    context.pushReplacement(AppRoutes.cleanupProgress);
                  }
                : null,
          ),
        ],
      ),
      children: staggered([
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.oneLastLook,
              style: AppText.custom(24, FontWeight.w600, context.tokens.textPrimary,
                  lineHeight: 30, letterSpacing: -0.6),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.oneLastLookBody,
              style: AppText.custom(14, FontWeight.w400, context.tokens.textSecondary,
                  lineHeight: 20),
            ),
          ],
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalBanner(
                label: AppStrings.selectedForCleanup,
                caption: AppStrings.categoriesSelected(cats.length),
                value: formatBytes(plan.bytes),
              ),
              for (final (i, c) in cats.indexed) ...[
                if (i > 0)
                  Divider(
                      height: 1, thickness: 1, color: context.tokens.border),
                CategoryRow(
                  category: c,
                  height: 64,
                  tile: 36,
                  hint: c.resultHint(plan.countFor(c), threshold),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RowValue(formatBytes(plan.bytesFor(c))),
                      const SizedBox(width: 12),
                      const _SelectedMark(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _keepHint,
              style: AppText.custom(12, FontWeight.w400, context.tokens.textCaption,
                  lineHeight: 16),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  AppStrings.changeSelection,
                  style: AppText.custom(13, FontWeight.w600,
                      context.tokens.textPrimary,
                      lineHeight: 18),
                ),
              ),
            ),
          ],
        ),
        InfoCard(
          title: AppStrings.whatHappensNext,
          body: ios ? AppStrings.whatHappensIos : AppStrings.whatHappensAndroid,
        ),
      ]),
    );
  }
}

/// Dải tổng "Selected for cleanup" nền xám nhạt, cao 64.
class _TotalBanner extends StatelessWidget {
  const _TotalBanner({
    required this.label,
    required this.caption,
    required this.value,
  });

  final String label;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: context.tokens.iconTile,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.custom(13, FontWeight.w600, context.tokens.textSecondary,
                    lineHeight: 18),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                style: AppText.custom(11, FontWeight.w400, context.tokens.textCaption,
                    lineHeight: 15),
              ),
            ],
          ),
          Text(
            value,
            style: AppText.custom(28, FontWeight.w700, context.tokens.textPrimary,
                lineHeight: 34, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}

/// Dấu tick đã chọn: vòng tròn tối có dấu check trắng.
class _SelectedMark extends StatelessWidget {
  const _SelectedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: context.tokens.textMuted,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 13, color: Colors.white),
    );
  }
}
