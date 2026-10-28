import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/scan_labels.dart';
import 'widgets/scan_widgets.dart';

class PartialResultsPage extends ConsumerWidget {
  const PartialResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(scanControllerProvider).outcome?.result;
    final config = ref.watch(scanConfigProvider);
    final done = result?.completed ?? const <ScanCategory>{};

    var count = 0;
    for (final c in done) {
      count += result?.count(c) ?? 0;
    }

    return PageScaffold(
      title: AppStrings.scanInterrupted,
      onBack: () => goHome(context),
      stickyFooter: true,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: AppStrings.reviewAvailable,
            // Không còn mục nào để xem thì không mở màn rỗng.
            onPressed: count == 0
                ? null
                : () => context.push(AppRoutes.scanComplete),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: AppStrings.retryRemaining,
            onPressed: () => restartScan(context, ref),
          ),
        ],
      ),
      children: [
        const StatePanel(icon: AppAssets.warning),
        Column(
          children: [
            const StatusText(AppStrings.partialBadge),
            const SizedBox(height: 8),
            Text(
              AppStrings.partialTitle,
              style: AppText.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.partialBody,
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        OutlinedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.availableToReview, style: AppText.statLabel),
              const SizedBox(height: 6),
              BigBytes(result == null ? 0 : _doneBytes(result, done)),
              const SizedBox(height: 4),
              Text(
                '${AppStrings.partialSubtotal} · ${formatCount(count)} items',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        Text(AppStrings.categoriesFinished, style: AppText.sectionTitle),
        OutlinedCard(
          child: Column(
            children: withDividers([
              for (final c in ScanCategory.values)
                CategoryRow(
                  icon: categoryIcon(c),
                  title: categoryTitle(c),
                  hint: categoryHint(c, config),
                  trailing: done.contains(c)
                      ? const StatusText(
                          AppStrings.completedValid,
                          color: AppColors.positive,
                        )
                      : const StatusText(
                          AppStrings.notFullyScanned,
                          color: AppColors.warnText,
                        ),
                ),
            ]),
          ),
        ),
        const InfoBanner(message: AppStrings.partialSafe),
      ],
    );
  }

  int _doneBytes(ScanResult r, Set<ScanCategory> done) =>
      done.fold(0, (sum, c) => sum + r.bytes(c));
}
