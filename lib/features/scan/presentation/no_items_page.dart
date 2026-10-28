import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import '../../permissions/application/media_access_controller.dart';
import '../../permissions/domain/media_access.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/scan_labels.dart';
import 'widgets/scan_widgets.dart';

class NoItemsPage extends ConsumerWidget {
  const NoItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(scanControllerProvider).outcome?.result;
    final config = ref.watch(scanConfigProvider);
    final limited =
        ref.watch(mediaAccessProvider).access == MediaAccess.limited;

    return PageScaffold(
      title: AppStrings.scanResults,
      onBack: () => goHome(context),
      stickyFooter: true,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: AppStrings.scanAgain,
            onPressed: () => restartScan(context, ref),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: AppStrings.backToHome,
            onPressed: () => goHome(context),
          ),
        ],
      ),
      children: [
        const StatePanel(icon: AppAssets.circleCheck),
        Column(
          children: [
            Text(
              AppStrings.noItemsTitle,
              style: AppText.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.noItemsBody,
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        Text(AppStrings.suggestedCleanup, style: AppText.sectionTitle),
        OutlinedCard(
          child: Column(
            children: withDividers([
              for (final c in ScanCategory.values)
                CategoryRow(
                  icon: categoryIcon(c),
                  title: categoryTitle(c),
                  hint: categoryHint(c, config),
                  trailing: StatusText(
                    (result?.completed.contains(c) ?? false)
                        ? AppStrings.noneFound
                        : AppStrings.notScanned,
                    color: AppColors.textMuted,
                  ),
                ),
            ]),
          ),
        ),
        if (limited)
          InfoRow(
            icon: AppAssets.info,
            title: AppStrings.authorizedOnlyTitle,
            body: AppStrings.authorizedOnlyBody,
          ),
      ],
    );
  }
}
