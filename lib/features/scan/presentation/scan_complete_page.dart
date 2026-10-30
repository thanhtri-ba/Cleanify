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
import '../domain/cleanup_plan.dart';
import '../domain/scan_models.dart';
import 'widgets/category_meta.dart';
import 'widgets/flow_parts.dart';

/// Scan Complete: tổng dung lượng có thể giải phóng + chọn danh mục.
class ScanCompletePage extends ConsumerWidget {
  const ScanCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(scanControllerProvider).outcome;
    final plan = ref.watch(cleanupPlanProvider);
    final threshold =
        formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final result = outcome?.result;

    void leave() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.home);

    if (result == null || plan == null) {
      return FlowScaffold(
        title: AppStrings.scanComplete,
        onBack: leave,
        children: const [SizedBox.shrink()],
      );
    }

    final canReview = !plan.isEmpty;
    return FlowScaffold(
      title: AppStrings.scanComplete,
      onBack: leave,
      bottom: FlowActionBar(
        children: [
          FlowPrimaryButton(
            label: AppStrings.reviewSelection(formatBytes(plan.bytes)),
            onPressed:
                canReview ? () => context.push(AppRoutes.cleanupReview) : null,
          ),
        ],
      ),
      children: staggered([
        const StateBadge(),
        Column(
          children: [
            Text(
              AppStrings.scanCompleteTitle,
              textAlign: TextAlign.center,
              style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                  lineHeight: 28, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.scanCompleteBody,
              textAlign: TextAlign.center,
              style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                  lineHeight: 20),
            ),
          ],
        ),
        CountUpBytes(
          bytes: plan.bytes,
          builder: (_, bytes) {
            final b = splitBytes(bytes);
            return Column(
              children: [
                Text(
                  AppStrings.potentialSpace,
                  style: AppText.custom(
                      12, FontWeight.w500, AppColors.textMuted,
                      lineHeight: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  b.toString(),
                  style: AppText.custom(40, FontWeight.w700, AppColors.primary,
                      lineHeight: 46, letterSpacing: -1),
                ),
              ],
            );
          },
        ),
        GroupCard(
          children: [
            for (final c in ScanCategory.values)
              _row(ref, result, plan, c, threshold),
          ],
        ),
      ]),
    );
  }

  Widget _row(WidgetRef ref, ScanResult result, CleanupPlan plan,
      ScanCategory c, String threshold) {
    final scanned = result.completed.contains(c);
    final selectable = plan.selectableIds(c).isNotEmpty;
    final selected = plan.isCategoryFullySelected(c);
    return CategoryRow(
      category: c,
      height: 56,
      tile: 34,
      hint: scanned ? c.resultHint(plan.countFor(c), threshold) : null,
      onTap: selectable
          ? () => ref.read(cleanupPlanProvider.notifier).toggleCategory(c)
          : null,
      trailing: !scanned
          ? const RowValue(AppStrings.notScanned, muted: true)
          : !selectable
              ? const RowValue(AppStrings.noneFound, muted: true)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RowValue(formatBytes(plan.bytesFor(c))),
                    const SizedBox(width: 10),
                    SelectCheck(selected: selected),
                  ],
                ),
    );
  }
}
