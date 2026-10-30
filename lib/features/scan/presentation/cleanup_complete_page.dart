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
import '../domain/scan_models.dart';
import 'widgets/flow_parts.dart';
import 'widgets/result_buttons.dart';

/// Cleanup Complete theo Figma 127:3300: tổng kết thật từ
/// [cleanupControllerProvider].
class CleanupCompletePage extends ConsumerWidget {
  const CleanupCompletePage({super.key});

  static const _summaryHeading = 'Cleanup summary';
  static const _completedTag = 'Completed';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cleanupControllerProvider);
    final outcome = s.outcome;
    final full = outcome?.isFullSuccess ?? false;
    final ios = isIosPlatform;
    final deletedCount = outcome?.deletedIds.length ?? 0;
    final canReviewRemaining =
        !full && (outcome?.remainingIds.isNotEmpty ?? false);
    final cats = [
      for (final c in ScanCategory.values)
        if (s.deletedByCategory.containsKey(c)) c,
    ];

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
        onBack: home,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        gap: 12,
        bottom: FlowActionBar(
          topBorder: context.tokens.border,
          children: [
            ResultPrimaryButton(
              label: AppStrings.backToHome,
              onPressed: home,
            ),
            if (canReviewRemaining)
              ResultSecondaryButton(
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
                style: AppText.custom(24, FontWeight.w600, context.tokens.textPrimary,
                    lineHeight: 30, letterSpacing: -0.6),
              ),
              const SizedBox(height: 6),
              Text(
                full
                    ? (ios ? AppStrings.movedIos : AppStrings.movedAndroid)
                    : AppStrings.cleanupPartialBody,
                textAlign: TextAlign.center,
                style: AppText.custom(14, FontWeight.w400, context.tokens.textSecondary,
                    lineHeight: 20),
              ),
            ],
          ),
          CountUpBytes(
            bytes: s.deletedBytes,
            builder: (_, bytes) => Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: context.tokens.iconTile,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.tokens.border),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        value: formatBytes(bytes),
                        label: AppStrings.reviewedMediaMoved,
                        color: const Color(0xFF4C4C4C),
                      ),
                    ),
                    VerticalDivider(
                        width: 1, thickness: 1, color: context.tokens.border),
                    Expanded(
                      child: _Stat(
                        value: formatCount(deletedCount),
                        label: AppStrings.itemsProcessed,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _summaryHeading,
                    style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary,
                        lineHeight: 18),
                  ),
                  Text(
                    _completedTag,
                    style: AppText.custom(12, FontWeight.w500,
                        context.tokens.textSecondary,
                        lineHeight: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GroupCard(
                children: [
                  for (final c in cats)
                    CategoryRow(
                      category: c,
                      height: 48,
                      tile: 30,
                      trailing:
                          RowValue(formatBytes(s.deletedByCategory[c] ?? 0)),
                    ),
                ],
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
            style: AppText.custom(12, FontWeight.w400, context.tokens.textCaption,
                lineHeight: 18),
          ),
        ]),
      ),
    );
  }
}

/// Một ô số liệu trong dải tổng: số lớn và nhãn nhỏ bên dưới.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppText.custom(28, FontWeight.w700, color,
              lineHeight: 34, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary,
              lineHeight: 16),
        ),
      ],
    );
  }
}
