import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/media_item.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../scan/presentation/widgets/flow_parts.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';

/// Large Files: video lớn từ kết quả quét, lọc theo ngưỡng, chọn để xóa
/// (xóa đi qua Review Cleanup).
class LargeFilesPage extends ConsumerStatefulWidget {
  const LargeFilesPage({super.key});

  @override
  ConsumerState<LargeFilesPage> createState() => _LargeFilesPageState();
}

class _LargeFilesPageState extends ConsumerState<LargeFilesPage> {
  /// Chỉ số ngưỡng đang chọn trong danh sách ngưỡng.
  int _thresholdIndex = 0;
  final Set<String> _selected = {};

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    final base = ref.watch(scanConfigProvider).largeVideoBytes;

    // Ngưỡng mặc định của quét, rồi các ngưỡng cao hơn.
    final thresholds = <int>[
      base,
      for (final t in const [500 * 1000 * 1000, 1000 * 1000 * 1000])
        if (t > base) t,
    ];
    final threshold =
        thresholds[_thresholdIndex.clamp(0, thresholds.length - 1)];

    if (result == null) {
      return SubPageScaffold(
        title: AppStrings.largeFiles,
        onBack: () => context.pop(),
        children: [
          const SubEmpty(
            asset: AppAssets.clapperboard,
            title: AppStrings.dupNotScannedTitle,
            body: AppStrings.dupNotScannedBody,
          ),
          PrimaryButton(
            label: AppStrings.scanNowShort,
            shadows: const [],
            onPressed: () => startScanFlow(context, ref),
          ),
        ],
      );
    }

    final videos = [
      for (final v in result.largeVideos)
        if ((v.sizeBytes ?? 0) >= threshold) v,
    ]..sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));

    final shownIds = {for (final v in videos) v.id};
    // Chỉ tính các video đang hiển thị theo ngưỡng hiện tại.
    final selected = _selected.where(shownIds.contains).toSet();
    var selectedBytes = 0;
    for (final v in videos) {
      if (selected.contains(v.id)) selectedBytes += v.sizeBytes ?? 0;
    }
    final total = videos.fold<int>(0, (s, v) => s + (v.sizeBytes ?? 0));
    final totalSize = splitBytes(total);

    return SubPageScaffold.lazy(
      title: AppStrings.largeFiles,
      onBack: () => context.pop(),
      action: shownIds.isEmpty
          ? null
          : SubPill(
              label: shownIds.every(selected.contains)
                  ? AppStrings.deselectAll
                  : AppStrings.selectAll,
              onTap: () => setState(() {
                if (shownIds.every(_selected.contains)) {
                  _selected.removeAll(shownIds);
                } else {
                  _selected.addAll(shownIds);
                }
              }),
            ),
      bottom: SubBottomBar(
        label: selected.isEmpty
            ? AppStrings.pickVideosToDelete
            : AppStrings.deleteVideos(
                selected.length, formatBytes(selectedBytes)),
        onPressed: selected.isEmpty
            ? null
            : () {
                ref.read(cleanupPlanProvider.notifier).selectOnly(selected);
                context.push(AppRoutes.cleanupReview);
              },
      ),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: thresholds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _ThresholdChip(
              label: '> ${formatBytes(thresholds[i])}',
              on: i == _thresholdIndex,
              onTap: () => setState(() => _thresholdIndex = i),
            ),
          ),
        ),
        SubCard(
          child: Row(
            children: [
              Expanded(
                child: SubBigStat(
                  value: totalSize.value,
                  unit: totalSize.unit,
                  caption: AppStrings.largeVideosCount(videos.length),
                ),
              ),
              const SubIconTile(
                  asset: AppAssets.clapperboard, size: 48, iconSize: 22),
            ],
          ),
        ),
        if (videos.isEmpty)
          const SubEmpty(
            asset: AppAssets.clapperboard,
            title: AppStrings.largeEmptyTitle,
            body: AppStrings.largeEmptyBody,
          ),
      ],
      itemCount: videos.length,
      itemBuilder: (context, i) => _VideoRow(
        item: videos[i],
        selected: selected.contains(videos[i].id),
        onTap: () => _toggle(videos[i].id),
      ),
    );
  }
}

class _ThresholdChip extends StatelessWidget {
  const _ThresholdChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
              color: on ? AppColors.primary : AppColors.borderNeutral),
        ),
        child: Text(
          label,
          style: AppText.custom(12.5, FontWeight.w600,
              on ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SubCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          MediaThumbnail(
            id: item.id,
            width: 72,
            height: 72,
            radius: 14,
            requestSize: 200,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatShortDate(item.createdAt),
                  style:
                      AppText.custom(14, FontWeight.w600, AppColors.titleInk),
                ),
                Text(
                  '${item.width}×${item.height}',
                  style:
                      AppText.custom(12, FontWeight.w400, AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  formatBytes(item.sizeBytes ?? 0),
                  style: AppText.custom(15, FontWeight.w700, AppColors.titleInk,
                      letterSpacing: -0.2),
                ),
              ],
            ),
          ),
          SelectCheck(selected: selected),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
