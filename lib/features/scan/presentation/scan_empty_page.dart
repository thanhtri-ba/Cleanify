import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../permissions/application/media_access_controller.dart';
import '../../permissions/domain/media_access.dart';
import '../application/scan_providers.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/category_meta.dart';
import 'widgets/flow_parts.dart';

/// No Items: quét xong nhưng không có gì để dọn.
class ScanEmptyPage extends ConsumerWidget {
  const ScanEmptyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = formatBytes(ref.watch(scanConfigProvider).largeVideoBytes);
    final limited =
        ref.watch(mediaAccessProvider).access == MediaAccess.limited;
    final total = ScanCategory.values.length;

    return FlowScaffold(
      title: AppStrings.scanComplete,
      onBack: () => context.go(AppRoutes.home),
      bottom: FlowActionBar(
        children: [
          FlowPrimaryButton(
            label: AppStrings.scanAgain,
            onPressed: () => restartScan(context, ref),
          ),
          FlowSecondaryButton(
            label: AppStrings.backToHome,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      children: staggered([
        const StateBadge(),
        Column(
          children: [
            Text(
              AppStrings.noItemsTitle,
              textAlign: TextAlign.center,
              style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                  lineHeight: 28, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.noItemsBody,
              textAlign: TextAlign.center,
              style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                  lineHeight: 20),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.scanResults,
                    style: AppText.custom(
                        14, FontWeight.w600, AppColors.titleInk,
                        lineHeight: 20),
                  ),
                  Text(
                    AppStrings.checkedOf(total, total),
                    style: AppText.custom(
                        12, FontWeight.w500, AppColors.textMuted,
                        lineHeight: 16),
                  ),
                ],
              ),
            ),
            GroupCard(
              children: [
                for (final c in ScanCategory.values)
                  CategoryRow(
                    category: c,
                    height: 52,
                    hint: c.scanningHint(threshold),
                    trailing: const RowValue(AppStrings.noneFound, muted: true),
                  ),
              ],
            ),
          ],
        ),
        if (limited)
          const InfoCard(
            title: AppStrings.authorizedOnlyTitle,
            body: AppStrings.authorizedOnlyBody,
          ),
      ]),
    );
  }
}
