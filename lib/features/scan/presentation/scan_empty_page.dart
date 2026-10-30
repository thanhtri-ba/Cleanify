import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../permissions/application/media_access_controller.dart';
import '../../permissions/domain/media_access.dart';
import '../domain/scan_models.dart';
import 'scan_actions.dart';
import 'widgets/flow_parts.dart';
import 'widgets/result_buttons.dart';

/// No Items theo Figma 127:3368: quét xong nhưng không có gì để dọn.
class ScanEmptyPage extends ConsumerWidget {
  const ScanEmptyPage({super.key});

  static const _suggestedLabel = 'Suggested cleanup';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limited =
        ref.watch(mediaAccessProvider).access == MediaAccess.limited;
    final total = ScanCategory.values.length;
    final zero = splitBytes(0);

    return FlowScaffold(
      title: AppStrings.scanComplete,
      onBack: () => context.go(AppRoutes.home),
      padding: const EdgeInsets.all(20),
      gap: 20,
      bottom: FlowActionBar(
        children: [
          ResultPrimaryButton(
            label: AppStrings.backToHome,
            onPressed: () => context.go(AppRoutes.home),
          ),
          ResultSecondaryButton(
            label: AppStrings.scanAgain,
            onPressed: () => restartScan(context, ref),
          ),
        ],
      ),
      children: staggered([
        Column(
          children: [
            const StateBadge(),
            const SizedBox(height: 10),
            Text(
              AppStrings.noItemsTitle,
              textAlign: TextAlign.center,
              style: AppText.custom(24, FontWeight.w600, context.tokens.textPrimary,
                  lineHeight: 30, letterSpacing: -0.6),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.noItemsBody,
              textAlign: TextAlign.center,
              style: AppText.custom(14, FontWeight.w400, context.tokens.textSecondary,
                  lineHeight: 20),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  zero.value,
                  style: AppText.custom(44, FontWeight.w700, context.tokens.textPrimary,
                      lineHeight: 48, letterSpacing: -2.2),
                ),
                const SizedBox(width: 5),
                Text(
                  zero.unit,
                  style: AppText.custom(20, FontWeight.w700,
                      context.tokens.textPrimary,
                      lineHeight: 26),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _suggestedLabel,
              style: AppText.custom(13, FontWeight.w500, context.tokens.textCaption,
                  lineHeight: 18),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.scanResults,
                    style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary,
                        lineHeight: 18),
                  ),
                  Text(
                    AppStrings.checkedOf(total, total),
                    style: AppText.custom(12, FontWeight.w500,
                        context.tokens.textSecondary,
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
