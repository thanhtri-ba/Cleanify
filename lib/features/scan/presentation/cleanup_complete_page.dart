import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/platform_copy.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import '../application/cleanup_controller.dart';
import '../application/scan_controller.dart';
import '../domain/cleanup_runner.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/scan_labels.dart';
import 'widgets/scan_widgets.dart';

class CleanupCompletePage extends ConsumerWidget {
  const CleanupCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cleanupControllerProvider);
    final scanResult = ref.watch(scanControllerProvider).outcome?.result;
    final outcome = s.outcome;

    if (outcome == null) {
      return PageScaffold(
        title: AppStrings.cleanupComplete,
        onBack: () => goHome(context),
        children: [
          SecondaryButton(
            label: AppStrings.backToHome,
            onPressed: () => goHome(context),
          ),
        ],
      );
    }

    final ios = isIosPlatform;
    final full = outcome.isFullSuccess;
    final hasRemaining =
        !full && scanResult != null && !scanResult.isEmpty;
    final categories = [
      for (final c in ScanCategory.values)
        if ((s.deletedByCategory[c] ?? 0) > 0) c,
    ];

    return PageScaffold(
      title: AppStrings.cleanupComplete,
      showBack: false,
      stickyFooter: true,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: AppStrings.backToHome,
            onPressed: () {
              ref.read(cleanupControllerProvider.notifier).reset();
              goHome(context);
            },
          ),
          if (hasRemaining) ...[
            const SizedBox(height: 8),
            SecondaryButton(
              label: AppStrings.reviewRemaining,
              onPressed: () {
                ref.read(cleanupControllerProvider.notifier).reset();
                context.pushReplacement(AppRoutes.scanComplete);
              },
            ),
          ],
        ],
      ),
      children: [
        const StatePanel(icon: AppAssets.circleCheck),
        Column(
          children: [
            Text(
              full
                  ? AppStrings.cleanupCompleteTitle
                  : AppStrings.cleanupPartialTitle,
              style: AppText.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              full
                  ? (ios ? AppStrings.movedIos : AppStrings.movedAndroid)
                  : _partialBody(outcome),
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        OutlinedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.reviewedMediaMoved, style: AppText.statLabel),
              const SizedBox(height: 6),
              BigBytes(s.deletedBytes),
              const SizedBox(height: 4),
              Text(
                '${AppStrings.itemsProcessed}: '
                '${formatCount(outcome.deletedIds.length)}',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty) ...[
          Text(AppStrings.cleanupSummary, style: AppText.sectionTitle),
          OutlinedCard(
            child: Column(
              children: withDividers([
                for (final c in categories)
                  CategoryRow(
                    icon: categoryIcon(c),
                    title: categoryTitle(c),
                    hint: AppStrings.completed,
                    trailing: Text(
                      formatBytes(s.deletedByCategory[c] ?? 0),
                      style: AppText.rowTitle,
                    ),
                  ),
              ]),
            ),
          ),
        ],
        if (outcome.deletedIds.isNotEmpty) ...[
          InfoRow(
            icon: AppAssets.info,
            title: AppStrings.needRecover,
            body: ios ? AppStrings.recoverIos : AppStrings.recoverAndroid,
          ),
          InfoBanner(
            message: ios
                ? AppStrings.storageNoteIos(formatBytes(s.deletedBytes))
                : AppStrings.storageNoteAndroid(formatBytes(s.deletedBytes)),
          ),
        ],
      ],
    );
  }

  String _partialBody(CleanupOutcome o) {
    if (o.declined) return AppStrings.deletionNotConfirmed;
    if (o.error != null) return AppStrings.cleanupFailed;
    if (o.cancelled) return AppStrings.cleanupStopped;
    return AppStrings.cleanupPartialBody;
  }
}
