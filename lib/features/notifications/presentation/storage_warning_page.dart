import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/ring_chart.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/scan_actions.dart';

/// Chi tiết thông báo "Bộ nhớ sắp đầy": mức dùng thật của máy và phần có thể
/// thu hồi từ kết quả quét.
class StorageWarningPage extends ConsumerWidget {
  const StorageWarningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(deviceStorageProvider);
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));

    final dupBytes = result == null
        ? 0
        : result.bytes(ScanCategory.duplicates) +
            result.bytes(ScanCategory.similar);
    final largeBytes = result?.bytes(ScanCategory.largeVideos) ?? 0;
    final dupGroups = result?.allGroups.length ?? 0;
    final largeCount = result?.largeVideos.length ?? 0;

    return SubPageScaffold(
      title: AppStrings.storageWarnTitle,
      onBack: () => context.pop(),
      bottom: SubBottomBar(
        label: result == null
            ? AppStrings.scanNowShort
            : AppStrings.storageWarnAnalysis,
        onPressed: result == null
            ? () => startScanFlow(context, ref)
            : () => context.push(AppRoutes.storageAnalysis),
      ),
      children: [
        storage.when(
          loading: () => const SubCard(
            child: SizedBox(
              height: 104,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (_, __) => const SubHint(AppStrings.analysisNoScan),
          data: (s) {
            final percent = (s.usedFraction * 100).round();
            return SubCard(
              child: Row(
                children: [
                  RingChart(
                    size: 104,
                    strokeWidth: 12,
                    segments: [
                      RingSegment(s.usedBytes.toDouble(), context.tokens.error)
                    ],
                    total: s.totalBytes.toDouble(),
                    center: Text(
                      '$percent%',
                      style: AppText.custom(
                          22, FontWeight.w700, context.tokens.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.storageWarnHeadline,
                          style: AppText.custom(
                              16, FontWeight.w600, context.tokens.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.storageWarnBody(
                            formatBytes(s.freeBytes),
                            formatBytes(s.totalBytes),
                          ),
                          style: AppText.custom(
                              13, FontWeight.w400, context.tokens.textMuted,
                              lineHeight: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SubSectionLabel(AppStrings.storageWarnFreeNow),
        if (result == null)
          const SubHint(AppStrings.analysisNoScan)
        else ...[
          _FreeableTile(
            asset: AppAssets.image,
            title: AppStrings.duplicatePhotos,
            caption: AppStrings.groupsReclaimable(dupGroups),
            bytes: dupBytes,
            onTap: () => context.push(AppRoutes.duplicates),
          ),
          _FreeableTile(
            asset: AppAssets.clapperboard,
            title: AppStrings.largeVideos,
            caption: AppStrings.largeVideosCount(largeCount),
            bytes: largeBytes,
            onTap: () => context.push(AppRoutes.largeFiles),
          ),
          SubCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.storageWarnTotal,
                    style: AppText.custom(
                        13, FontWeight.w400, context.tokens.textMuted),
                  ),
                ),
                Text(
                  formatBytes(dupBytes + largeBytes),
                  style:
                      AppText.custom(14, FontWeight.w700, context.tokens.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FreeableTile extends StatelessWidget {
  const _FreeableTile({
    required this.asset,
    required this.title,
    required this.caption,
    required this.bytes,
    required this.onTap,
  });

  final String asset;
  final String title;
  final String caption;
  final int bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SubCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          SubIconTile(asset: asset),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppText.custom(14, FontWeight.w600, context.tokens.textPrimary),
                ),
                Text(
                  caption,
                  style: AppText.custom(
                      12.5, FontWeight.w400, context.tokens.textMuted),
                ),
              ],
            ),
          ),
          Text(
            formatBytes(bytes),
            style: AppText.custom(14, FontWeight.w700, context.tokens.textPrimary),
          ),
          const SizedBox(width: 6),
          AppSvg(AppAssets.chevronRight,
              size: 14, color: context.tokens.textMuted),
        ],
      ),
    );
  }
}
