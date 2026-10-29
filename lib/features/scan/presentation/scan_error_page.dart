import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import 'scan_actions.dart';
import 'widgets/flow_parts.dart';

/// Scan Error: quét lỗi và chưa có kết quả hợp lệ nào.
class ScanErrorPage extends ConsumerWidget {
  const ScanErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlowScaffold(
      title: AppStrings.storageScan,
      onBack: () => context.go(AppRoutes.home),
      bottom: FlowActionBar(
        children: [
          FlowPrimaryButton(
            label: AppStrings.tryAgain,
            onPressed: () => restartScan(context, ref),
          ),
          FlowSecondaryButton(
            label: AppStrings.backToScan,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      children: staggered([
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.errorTint,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: AppSvg(AppAssets.warning, size: 28, color: AppColors.error),
            ),
          ),
        ),
        Column(
          children: [
            Text(
              AppStrings.scanErrorTitle,
              textAlign: TextAlign.center,
              style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                  lineHeight: 28, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.scanErrorBody,
              textAlign: TextAlign.center,
              style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                  lineHeight: 20),
            ),
          ],
        ),
        const InfoCard(
          title: AppStrings.scanInterrupted,
          body: AppStrings.scanErrorSafe,
        ),
      ]),
    );
  }
}
