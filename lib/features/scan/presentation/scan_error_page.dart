import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import 'scan_actions.dart';

class ScanErrorPage extends ConsumerWidget {
  const ScanErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: AppStrings.storageScan,
      onBack: () => goHome(context),
      stickyFooter: true,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: AppStrings.tryAgain,
            color: AppColors.violetDeep,
            onPressed: () => restartScan(context, ref),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: AppStrings.backToScan,
            onPressed: () => goHome(context),
          ),
        ],
      ),
      children: [
        const StatePanel(icon: AppAssets.warning),
        Column(
          children: [
            Text(
              AppStrings.scanErrorTitle,
              style: AppText.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.scanErrorBody,
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const InfoBanner(message: AppStrings.scanErrorSafe),
      ],
    );
  }
}
