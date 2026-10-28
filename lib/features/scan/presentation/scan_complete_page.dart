import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import '../application/scan_controller.dart';
import '../domain/cleanup_plan.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/scan_labels.dart';
import 'widgets/scan_widgets.dart';

class ScanCompletePage extends ConsumerWidget {
  const ScanCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(scanControllerProvider).outcome;
    final plan = ref.watch(cleanupPlanProvider);

    if (outcome == null || plan == null) {
      return const _NoResults();
    }

    final result = outcome.result;
    final notifier = ref.read(cleanupPlanProvider.notifier);

    return PageScaffold(
      title: AppStrings.scanComplete,
      onBack: () => goHome(context),
      stickyFooter: true,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: AppStrings.reviewSelection(formatBytes(plan.bytes)),
            onPressed: plan.isEmpty
                ? null
                : () => context.push(AppRoutes.cleanupReview),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.nothingDeletedUntilConfirm,
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      children: [
        const StatePanel(icon: AppAssets.circleCheck),
        Column(
          children: [
            Text(
              AppStrings.scanCompleteTitle,
              style: AppText.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.scanCompleteBody,
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        OutlinedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.potentialSpace, style: AppText.statLabel),
              const SizedBox(height: 6),
              BigBytes(plan.bytes),
            ],
          ),
        ),
        Text(AppStrings.selectedForReview, style: AppText.sectionTitle),
        OutlinedCard(
          child: Column(
            children: withDividers([
              for (final c in ScanCategory.values)
                _row(c, result, plan, notifier),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _row(
    ScanCategory c,
    ScanResult result,
    CleanupPlan plan,
    CleanupPlanNotifier notifier,
  ) {
    final done = result.completed.contains(c);
    final selectable = plan.selectableIds(c).length;
    final hasAny = done && selectable > 0;
    final selected = plan.countFor(c);

    final String hint;
    if (!done) {
      hint = AppStrings.notScanned;
    } else if (result.count(c) == 0) {
      hint = AppStrings.noneFound;
    } else {
      hint = '${formatCount(result.count(c))} · '
          '${formatBytes(result.bytes(c))}';
    }

    return CategoryRow(
      icon: categoryIcon(c),
      title: categoryTitle(c),
      hint: hint,
      dimmed: !hasAny,
      trailing: Checkbox(
        tristate: true,
        activeColor: AppColors.primary,
        value: plan.isCategoryFullySelected(c)
            ? true
            : (selected > 0 ? null : false),
        onChanged: hasAny ? (_) => notifier.toggleCategory(c) : null,
      ),
    );
  }
}

/// Hiện khi mở màn kết quả mà không còn kết quả quét trong bộ nhớ.
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppStrings.scanComplete,
      onBack: () => goHome(context),
      children: [
        const StatePanel(icon: AppAssets.imageOff),
        Text(
          AppStrings.noScanYet,
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        SecondaryButton(
          label: AppStrings.backToHome,
          onPressed: () => goHome(context),
        ),
      ],
    );
  }
}
