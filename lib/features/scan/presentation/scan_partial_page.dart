import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/category_meta.dart';
import 'widgets/flow_parts.dart';

/// Scan Interrupted: quét dừng giữa chừng nhưng đã có kết quả hợp lệ.
class ScanPartialPage extends ConsumerWidget {
  const ScanPartialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(scanControllerProvider).outcome?.result;
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    if (result == null) {
      return FlowScaffold(
        title: AppStrings.scanInterrupted,
        onBack: () => context.go(AppRoutes.home),
        children: const [SizedBox.shrink()],
      );
    }
    final done = result.completed;
    final doneBytes =
        [for (final c in done) result.bytes(c)].fold<int>(0, (a, b) => a + b);

    return FlowScaffold(
      title: AppStrings.scanInterrupted,
      onBack: () => context.go(AppRoutes.home),
      bottom: FlowActionBar(
        children: [
          FlowPrimaryButton(
            label: AppStrings.reviewAvailable,
            onPressed: () => context.push(AppRoutes.scanComplete),
          ),
          FlowSecondaryButton(
            label: AppStrings.retryRemaining,
            onPressed: () => restartScan(context, ref),
          ),
        ],
      ),
      children: staggered([
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.errorTint,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                AppStrings.partialBadge,
                style: AppText.custom(11, FontWeight.w600, AppColors.error,
                    lineHeight: 14, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.partialTitle,
              textAlign: TextAlign.center,
              style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                  lineHeight: 28, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.partialBody,
              textAlign: TextAlign.center,
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
                    AppStrings.availableToReview,
                    style: AppText.custom(
                        12, FontWeight.w500, AppColors.textMuted,
                        lineHeight: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatBytes(doneBytes),
                    style: AppText.custom(
                        32, FontWeight.w700, AppColors.primary,
                        lineHeight: 38, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.partialSubtotal,
                    style: AppText.custom(
                        12, FontWeight.w400, AppColors.textBody,
                        lineHeight: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                AppStrings.categoriesFinished,
                style: AppText.custom(14, FontWeight.w600, AppColors.titleInk,
                    lineHeight: 20),
              ),
            ),
            GroupCard(
              children: [
                for (final c in ScanCategory.values)
                  CategoryRow(
                    category: c,
                    height: 52,
                    hint: done.contains(c)
                        ? AppStrings.completedValid
                        : AppStrings.notFullyScanned,
                    trailing: done.contains(c)
                        ? RowValue(formatBytes(result.bytes(c)))
                        : const RowValue(AppStrings.notScanned, muted: true),
                  ),
              ],
            ),
          ],
        ),
        const InfoCard(
          title: AppStrings.scanInterrupted,
          body: AppStrings.partialSafe,
        ),
      ]),
    );
  }
}
