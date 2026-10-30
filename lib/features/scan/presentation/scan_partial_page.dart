import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/category_meta.dart';
import 'widgets/flow_parts.dart';
import 'widgets/result_buttons.dart';

/// Scan Interrupted theo Figma 127:3433: quét dừng giữa chừng nhưng đã có
/// kết quả hợp lệ. Dữ liệu lấy từ kết quả quét thật.
class ScanPartialPage extends ConsumerWidget {
  const ScanPartialPage({super.key});

  static const _pendingLabel = 'Pending';
  static const _completedHeading = 'Completed · valid results';
  static const _pendingHeading = 'Not fully scanned';
  static const _safeNote =
      'No files have been deleted. Retry to finish the remaining categories.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(scanControllerProvider).outcome?.result;
    if (result == null) {
      return FlowScaffold(
        title: AppStrings.scanInterrupted,
        onBack: () => context.go(AppRoutes.home),
        children: const [SizedBox.shrink()],
      );
    }
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final done = result.completed;
    final total = ScanCategory.values.length;
    final doneCats = [
      for (final c in ScanCategory.values)
        if (done.contains(c)) c,
    ];
    final pendingCats = [
      for (final c in ScanCategory.values)
        if (!done.contains(c)) c,
    ];
    final doneBytes =
        [for (final c in done) result.bytes(c)].fold<int>(0, (a, b) => a + b);

    return FlowScaffold(
      title: AppStrings.scanInterrupted,
      onBack: () => context.go(AppRoutes.home),
      bottom: FlowActionBar(
        children: [
          ResultPrimaryButton(
            label: AppStrings.reviewAvailable,
            onPressed: () => context.push(AppRoutes.scanComplete),
          ),
          ResultSecondaryButton(
            label: AppStrings.retryRemaining,
            onPressed: () => restartScan(context, ref),
          ),
        ],
      ),
      children: staggered([
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                AppStrings.partialBadge,
                style: AppText.custom(11, FontWeight.w600,
                    context.tokens.textSecondary,
                    lineHeight: 14, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.partialTitle,
              style: AppText.custom(24, FontWeight.w600, context.tokens.textPrimary,
                  lineHeight: 30, letterSpacing: -0.6),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.partialBody,
              style: AppText.custom(14, FontWeight.w400, context.tokens.textSecondary,
                  lineHeight: 20),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.tokens.iconTile,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.availableToReview,
                        style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary,
                            lineHeight: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.partialSubtotal,
                        style: AppText.custom(
                            12, FontWeight.w400, context.tokens.textSecondary,
                            lineHeight: 16),
                      ),
                    ],
                  ),
                  Text(
                    formatBytes(doneBytes),
                    style: AppText.custom(28, FontWeight.w700,
                        context.tokens.textPrimary,
                        lineHeight: 34, letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: context.tokens.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.categoriesFinished,
                    style: AppText.custom(
                        12, FontWeight.w400, context.tokens.textSecondary,
                        lineHeight: 16),
                  ),
                  Text(
                    '${done.length} of $total',
                    style: AppText.custom(12, FontWeight.w600,
                        context.tokens.textPrimary,
                        lineHeight: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < total; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: i < done.length
                                ? FlowColors.progress
                                : context.tokens.iconTile,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _completedHeading,
              style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary,
                  lineHeight: 18),
            ),
            const SizedBox(height: 8),
            GroupCard(
              color: context.tokens.surface,
              radius: 20,
              children: [
                for (final c in doneCats)
                  CategoryRow(
                    category: c,
                    height: 64,
                    tile: 36,
                    hint: c.resultHint(result.count(c), threshold),
                    trailing: RowValue(formatBytes(result.bytes(c))),
                  ),
              ],
            ),
          ],
        ),
        if (pendingCats.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pendingHeading,
                style: AppText.custom(13, FontWeight.w600, context.tokens.textCaption,
                    lineHeight: 18),
              ),
              const SizedBox(height: 8),
              GroupCard(
                color: context.tokens.surface,
                bordered: false,
                radius: 20,
                children: [
                  for (final c in pendingCats)
                    CategoryRow(
                      category: c,
                      trailing: Text(
                        _pendingLabel,
                        style: AppText.custom(
                            14, FontWeight.w500, context.tokens.textCaption,
                            lineHeight: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
        Text(
          _safeNote,
          textAlign: TextAlign.center,
          style: AppText.custom(12, FontWeight.w400, context.tokens.textCaption,
              lineHeight: 18),
        ),
      ]),
    );
  }
}
