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
import '../domain/scan_models.dart';
import 'widgets/flow_parts.dart';

/// Cleanup Complete: tổng kết thật từ [cleanupControllerProvider].
class CleanupCompletePage extends ConsumerWidget {
  const CleanupCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cleanupControllerProvider);
    final outcome = s.outcome;
    final full = outcome?.isFullSuccess ?? false;
    final ios = isIosPlatform;
    final deletedCount = outcome?.deletedIds.length ?? 0;

    void home() {
      ref.read(cleanupControllerProvider.notifier).reset();
      context.go(AppRoutes.home);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: FlowScaffold(
        title: AppStrings.cleanupComplete,
        bottom: FlowActionBar(
          children: [
            if (!full && (outcome?.remainingIds.isNotEmpty ?? false))
              FlowSecondaryButton(
                label: AppStrings.reviewRemaining,
                onPressed: () {
                  ref.read(cleanupControllerProvider.notifier).reset();
                  final result =
                      ref.read(scanControllerProvider).outcome?.result;
                  if (result != null) {
                    ref.read(cleanupPlanProvider.notifier).reset(result);
                  }
                  context.go(AppRoutes.home);
                  context.push(AppRoutes.cleanupReview);
                },
              ),
            FlowPrimaryButton(label: AppStrings.backToHome, onPressed: home),
          ],
        ),
        children: staggered([
          const StateBadge(),
          Column(
            children: [
              Text(
                full
                    ? AppStrings.cleanupCompleteTitle
                    : AppStrings.cleanupPartialTitle,
                textAlign: TextAlign.center,
                style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                    lineHeight: 28, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(
                full
                    ? (ios ? AppStrings.movedIos : AppStrings.movedAndroid)
                    : AppStrings.cleanupPartialBody,
                textAlign: TextAlign.center,
                style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                    lineHeight: 20),
              ),
            ],
          ),
          CountUpBytes(
            bytes: s.deletedBytes,
            builder: (_, bytes) => Column(
              children: [
                Text(
                  AppStrings.reviewedMediaMoved,
                  style: AppText.custom(
                      12, FontWeight.w500, AppColors.textMuted,
                      lineHeight: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  formatBytes(bytes),
                  style: AppText.custom(40, FontWeight.w700, AppColors.primary,
                      lineHeight: 46, letterSpacing: -1),
                ),
                Text(
                  '${AppStrings.itemsProcessed}: ${formatCount(deletedCount)}',
                  style: AppText.custom(12, FontWeight.w400, AppColors.textBody,
                      lineHeight: 16),
                ),
              ],
            ),
          ),
          GroupCard(
            children: [
              for (final c in ScanCategory.values)
                if (s.deletedByCategory.containsKey(c))
                  CategoryRow(
                    category: c,
                    height: 52,
                    trailing:
                        RowValue(formatBytes(s.deletedByCategory[c] ?? 0)),
                  ),
            ],
          ),
          InfoCard(
            title: AppStrings.needRecover,
            body: ios ? AppStrings.recoverIos : AppStrings.recoverAndroid,
          ),
          Text(
            ios
                ? AppStrings.storageNoteIos(formatBytes(s.deletedBytes))
                : AppStrings.storageNoteAndroid(formatBytes(s.deletedBytes)),
            textAlign: TextAlign.center,
            style: AppText.custom(11, FontWeight.w400, AppColors.textMuted,
                lineHeight: 15),
          ),
        ]),
      ),
    );
  }
}
