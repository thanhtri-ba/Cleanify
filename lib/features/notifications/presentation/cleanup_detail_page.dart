import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/utils/platform_copy.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/application/cleanup_controller.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/presentation/widgets/category_meta.dart';
import '../../scan/presentation/widgets/flow_parts.dart';

/// Chi tiết thông báo "Dọn dẹp hoàn tất", lấy từ lần dọn gần nhất trong phiên.
class CleanupDetailPage extends ConsumerWidget {
  const CleanupDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastCleanupProvider);
    final hasRemaining = ref.watch(scanControllerProvider
        .select((s) => s.outcome?.result.allGroups.isNotEmpty ?? false));
    final ios = isIosPlatform;

    if (last == null) {
      return SubPageScaffold(
        title: AppStrings.cleanupDetailTitle,
        onBack: () => context.pop(),
        children: const [
          SubEmpty(
            asset: AppAssets.check,
            title: AppStrings.notifEmptyTitle,
            body: AppStrings.cleanupDetailEmpty,
          ),
        ],
      );
    }

    return SubPageScaffold(
      title: AppStrings.cleanupDetailTitle,
      onBack: () => context.pop(),
      bottom: hasRemaining
          ? SubBottomBar(
              label: AppStrings.viewRemainingDuplicates,
              onPressed: () => context.push(AppRoutes.duplicates),
            )
          : null,
      children: [
        SubCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppSvg(AppAssets.check, size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              CountUpBytes(
                bytes: last.bytes,
                builder: (_, bytes) {
                  final s = splitBytes(bytes);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        s.value,
                        style: AppText.custom(
                            40, FontWeight.w700, context.tokens.textPrimary,
                            lineHeight: 46, letterSpacing: -1.2),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.unit,
                        style: AppText.custom(
                            16, FontWeight.w600, context.tokens.textMuted),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                '${AppStrings.cleanupDetailReclaimed} · ${agoLabel(last.at)}',
                style: AppText.custom(13, FontWeight.w400, context.tokens.textMuted),
              ),
            ],
          ),
        ),
        GroupCard(
          shadow: true,
          children: [
            _KeyValue(
              AppStrings.cleanupDetailItems,
              formatCount(last.count),
            ),
            _KeyValue(
              AppStrings.cleanupDetailWhere,
              ios
                  ? AppStrings.cleanupDetailWhereIos
                  : AppStrings.cleanupDetailWhereAndroid,
            ),
            for (final e in last.byCategory.entries)
              if (e.value > 0) _KeyValue(e.key.label, formatBytes(e.value)),
          ],
        ),
        InfoCard(
          title: AppStrings.needRecover,
          body: ios ? AppStrings.recoverIos : AppStrings.recoverAndroid,
        ),
        Text(
          ios
              ? AppStrings.storageNoteIos(formatBytes(last.bytes))
              : AppStrings.storageNoteAndroid(formatBytes(last.bytes)),
          textAlign: TextAlign.center,
          style: AppText.custom(11, FontWeight.w400, context.tokens.textMuted,
              lineHeight: 15),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.custom(13.5, FontWeight.w400, context.tokens.textMuted),
            ),
          ),
          Text(
            value,
            style: AppText.custom(13.5, FontWeight.w600, context.tokens.textPrimary),
          ),
        ],
      ),
    );
  }
}
