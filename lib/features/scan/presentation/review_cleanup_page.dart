import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/platform_copy.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../application/cleanup_controller.dart';
import '../application/scan_controller.dart';
import 'scan_actions.dart';
import 'widgets/scan_labels.dart';
import 'widgets/scan_widgets.dart';

class ReviewCleanupPage extends ConsumerWidget {
  const ReviewCleanupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(cleanupPlanProvider);

    if (plan == null || plan.isEmpty) {
      // Không còn gì được chọn (vd. đã xóa hết): quay về Home.
      return PageScaffold(
        title: AppStrings.reviewCleanup,
        onBack: () => goHome(context),
        children: [
          Text(
            AppStrings.noItemsBody,
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

    final categories = plan.selectedCategories;
    final ios = isIosPlatform;

    return PageScaffold(
      title: AppStrings.reviewCleanup,
      stickyFooter: true,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ios ? AppStrings.nextConfirmIos : AppStrings.nextConfirmAndroid,
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: AppStrings.startCleanup,
            onPressed: () {
              ref.read(cleanupControllerProvider.notifier).start();
              context.pushReplacement(AppRoutes.cleanupProgress);
            },
          ),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.oneLastLook, style: AppText.display),
            const SizedBox(height: 6),
            Text(AppStrings.oneLastLookBody, style: AppText.body),
          ],
        ),
        OutlinedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.selectedForCleanup, style: AppText.statLabel),
              const SizedBox(height: 6),
              BigBytes(plan.bytes),
              const SizedBox(height: 4),
              Text(
                AppStrings.categoriesSelected(categories.length),
                style: AppText.caption,
              ),
              const RowDivider(),
              Column(
                children: withDividers([
                  for (final c in categories)
                    CategoryRow(
                      icon: categoryIcon(c),
                      title: categoryTitle(c),
                      hint: '${formatCount(plan.countFor(c))} items',
                      trailing: Text(
                        formatBytes(plan.bytesFor(c)),
                        style: AppText.rowTitle,
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ),
        OutlinedCard(
          child: Row(
            children: [
              Expanded(
                child: Text(AppStrings.wantToKeep, style: AppText.rowTitle),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  AppStrings.changeSelection,
                  style: AppText.linkAccent,
                ),
              ),
            ],
          ),
        ),
        InfoRow(
          icon: AppAssets.info,
          title: AppStrings.whatHappensNext,
          body: ios ? AppStrings.whatHappensIos : AppStrings.whatHappensAndroid,
        ),
      ],
    );
  }
}
