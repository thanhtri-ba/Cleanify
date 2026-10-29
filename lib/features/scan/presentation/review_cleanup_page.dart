import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/platform_copy.dart';
import '../application/cleanup_controller.dart';
import '../application/scan_controller.dart';
import 'widgets/flow_parts.dart';

/// Review Cleanup: xác nhận lần cuối trước khi hệ điều hành hỏi xóa.
class ReviewCleanupPage extends ConsumerWidget {
  const ReviewCleanupPage({super.key});

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
    final cats = plan.selectedCategories;

    return FlowScaffold(
      title: AppStrings.reviewCleanup,
      onBack: () => context.pop(),
      bottom: FlowActionBar(
        children: [
          FlowPrimaryButton(
            label: AppStrings.startCleanup,
            onPressed: plan.isEmpty
                ? null
                : () {
                    ref.read(cleanupControllerProvider.notifier).start();
                    context.pushReplacement(AppRoutes.cleanupProgress);
                  },
          ),
          FlowSecondaryButton(
            label: AppStrings.changeSelection,
            onPressed: () => context.pop(),
          ),
        ],
      ),
      children: staggered([
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.oneLastLook,
              style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                  lineHeight: 28, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.oneLastLookBody,
              style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                  lineHeight: 20),
            ),
          ],
        ),
        GroupCard(
          color: AppColors.iconTile,
          bordered: false,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.selectedForCleanup,
                    style: AppText.custom(
                        12, FontWeight.w500, AppColors.textMuted,
                        lineHeight: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatBytes(plan.bytes),
                    style: AppText.custom(
                        32, FontWeight.w700, AppColors.primary,
                        lineHeight: 38, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatCount(plan.count)} items · '
                    '${AppStrings.categoriesSelected(cats.length)}',
                    style: AppText.custom(
                        12, FontWeight.w400, AppColors.textBody,
                        lineHeight: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        InfoCard(
          title: AppStrings.whatHappensNext,
          body: ios ? AppStrings.whatHappensIos : AppStrings.whatHappensAndroid,
        ),
        Text(
          ios ? AppStrings.nextConfirmIos : AppStrings.nextConfirmAndroid,
          textAlign: TextAlign.center,
          style: AppText.custom(12, FontWeight.w500, AppColors.textMuted,
              lineHeight: 16),
        ),
      ]),
    );
  }
}
