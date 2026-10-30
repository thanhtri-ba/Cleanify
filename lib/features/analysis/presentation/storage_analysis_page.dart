import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/ring_chart.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/device_storage.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/widgets/flow_parts.dart';

/// Storage Analysis: phân bổ dung lượng và những gì có thể giải phóng.
/// Phân bổ ảnh/video chỉ có khi [storageBreakdownProvider] có dữ liệu; nếu
/// chưa thì hiện Used/Free của thiết bị.
class StorageAnalysisPage extends ConsumerWidget {
  const StorageAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(storageBreakdownProvider);
    final storage = ref.watch(deviceStorageProvider);
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));

    final Widget chart;
    if (breakdown != null) {
      chart = _ChartCard(
        segments: [
          RingSegment(
              breakdown.photosBytes.toDouble(), AppColors.breakdownPhotos),
          RingSegment(
              breakdown.videosBytes.toDouble(), AppColors.breakdownVideos),
          RingSegment(breakdown.screenshotsBytes.toDouble(),
              AppColors.breakdownScreenshots),
        ],
        centerBytes: breakdown.totalBytes,
        legend: [
          _LegendItem(AppColors.breakdownPhotos, AppStrings.legendPhotos,
              breakdown.photosBytes),
          _LegendItem(AppColors.breakdownVideos, AppStrings.legendVideos,
              breakdown.videosBytes),
          _LegendItem(AppColors.breakdownScreenshots, AppStrings.screenshots,
              breakdown.screenshotsBytes),
        ],
        footerLabel: AppStrings.analysisTotalMedia,
        footerBytes: breakdown.totalBytes,
      );
    } else {
      chart = storage.when(
        loading: () => const SubCard(
          child: SizedBox(
            height: 128,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        error: (_, __) => const SubHint(AppStrings.analysisNoScan),
        data: (DeviceStorage s) => _ChartCard(
          segments: [RingSegment(s.usedBytes.toDouble(), AppColors.primary)],
          total: s.totalBytes.toDouble(),
          centerBytes: s.usedBytes,
          legend: [
            _LegendItem(AppColors.primary, AppStrings.legendUsed, s.usedBytes),
            _LegendItem(
                AppColors.segmentOff, AppStrings.legendFree, s.freeBytes),
          ],
          footerLabel: AppStrings.analysisUsedOfTotal,
          footerBytes: s.totalBytes,
          footerIsTotal: true,
        ),
      );
    }

    final hasDup = result != null && result.allGroups.isNotEmpty;
    final hasLarge = result != null && result.largeVideos.isNotEmpty;
    final dupBytes = result == null
        ? 0
        : result.bytes(ScanCategory.duplicates) +
            result.bytes(ScanCategory.similar);
    final largeCount = result?.largeVideos.length ?? 0;
    final largeBytes = result?.bytes(ScanCategory.largeVideos) ?? 0;

    return SubPageScaffold(
      title: AppStrings.storageAnalysis,
      onBack: () => context.pop(),
      children: [
        chart,
        const SubSectionLabel(AppStrings.analysisFreeable),
        if (result == null)
          const SubHint(AppStrings.analysisNoScan)
        else
          GroupCard(
            shadow: true,
            children: [
              for (final c in ScanCategory.values)
                CategoryRow(
                  category: c,
                  height: 56,
                  hint: AppStrings.albumItems(result.count(c)),
                  trailing: RowValue(formatBytes(result.bytes(c))),
                ),
            ],
          ),
        if (hasDup || hasLarge)
          const SubSectionLabel(AppStrings.analysisSuggestions),
        if (hasDup)
          _TipTile(
            asset: AppAssets.image,
            title: AppStrings.suggestDuplicates,
            caption: formatBytes(dupBytes),
            onTap: () => context.push(AppRoutes.duplicates),
          ),
        if (hasLarge)
          _TipTile(
            asset: AppAssets.clapperboard,
            title: AppStrings.suggestLarge,
            caption:
                '${AppStrings.largeVideosCount(largeCount)} · ${formatBytes(largeBytes)}',
            onTap: () => context.push(AppRoutes.largeFiles),
          ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem(this.color, this.label, this.bytes);

  final Color color;
  final String label;
  final int bytes;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.segments,
    required this.centerBytes,
    required this.legend,
    required this.footerLabel,
    required this.footerBytes,
    this.total,
    this.footerIsTotal = false,
  });

  final List<RingSegment> segments;
  final double? total;
  final int centerBytes;
  final List<_LegendItem> legend;
  final String footerLabel;
  final int footerBytes;

  /// true: dòng cuối là "tổng dung lượng máy" thay vì tổng ảnh/video.
  final bool footerIsTotal;

  @override
  Widget build(BuildContext context) {
    final center = splitBytes(centerBytes);
    return SubCard(
      child: Row(
        children: [
          RingChart(
            segments: segments,
            total: total,
            trackColor: total != null ? AppColors.segmentOff : AppColors.chip,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  center.value,
                  style:
                      AppText.custom(18, FontWeight.w700, AppColors.titleInk),
                ),
                Text(
                  center.unit,
                  style:
                      AppText.custom(11, FontWeight.w500, AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final l in legend) ...[
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: l.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.label,
                          style: AppText.custom(
                              13, FontWeight.w400, AppColors.textBody),
                        ),
                      ),
                      Text(
                        formatBytes(l.bytes),
                        style: AppText.custom(
                            13, FontWeight.w600, AppColors.titleInk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const Divider(height: 1, color: AppColors.divider2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        footerIsTotal
                            ? '${AppStrings.analysisUsedOfTotal} / ${formatBytes(footerBytes)}'
                            : footerLabel,
                        style: AppText.custom(
                            12, FontWeight.w400, AppColors.textMuted),
                      ),
                    ),
                    if (!footerIsTotal)
                      Text(
                        formatBytes(footerBytes),
                        style: AppText.custom(
                            13, FontWeight.w600, AppColors.titleInk),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({
    required this.asset,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final String asset;
  final String title;
  final String caption;
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
                      AppText.custom(14, FontWeight.w600, AppColors.titleInk),
                ),
                Text(
                  caption,
                  style: AppText.custom(
                      12.5, FontWeight.w400, AppColors.textMuted),
                ),
              ],
            ),
          ),
          const AppSvg(AppAssets.chevronRight,
              size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
