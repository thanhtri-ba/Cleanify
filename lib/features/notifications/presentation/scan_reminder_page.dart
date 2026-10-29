import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../scan/presentation/widgets/flow_parts.dart';

/// Chi tiết thông báo nhắc quét. Hiện chưa lên lịch nhắc định kỳ nên chỉ báo
/// trạng thái quét và cho quét ngay.
class ScanReminderPage extends ConsumerWidget {
  const ScanReminderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanned =
        ref.watch(scanControllerProvider.select((s) => s.outcome != null));
    final running = ref.watch(
        scanControllerProvider.select((s) => s.phase == ScanPhase.running));

    return SubPageScaffold(
      title: AppStrings.reminderTitle,
      onBack: () => context.pop(),
      bottom: SubBottomBar(
        label: scanned ? AppStrings.rescanShort : AppStrings.scanNowShort,
        onPressed: running ? null : () => startScanFlow(context, ref),
      ),
      children: [
        SubCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const SubIconTile(
                  asset: AppAssets.scanTarget, size: 48, iconSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanned
                          ? AppStrings.reminderDone
                          : AppStrings.reminderNever,
                      style: AppText.custom(
                          16, FontWeight.w600, AppColors.titleInk),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scanned
                          ? AppStrings.reminderDoneBody
                          : AppStrings.reminderNeverBody,
                      style: AppText.custom(
                          13, FontWeight.w400, AppColors.textMuted,
                          lineHeight: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const InfoCard(
          title: AppStrings.reminderInfoTitle,
          body: AppStrings.reminderInfoBody,
        ),
      ],
    );
  }
}
