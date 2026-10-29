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
import '../../scan/domain/media_item.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../scan/presentation/widgets/flow_parts.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';

enum _DupFilter { all, exact, similar }

/// Duplicate Photos: duyệt từng nhóm ảnh trùng/tương tự, chọn bản muốn xóa.
/// Bản đầu tiên của mỗi nhóm luôn được giữ lại. Xóa đi qua Review Cleanup.
class DuplicatePhotosPage extends ConsumerStatefulWidget {
  const DuplicatePhotosPage({super.key});

  @override
  ConsumerState<DuplicatePhotosPage> createState() =>
      _DuplicatePhotosPageState();
}

class _DuplicatePhotosPageState extends ConsumerState<DuplicatePhotosPage> {
  _DupFilter _filter = _DupFilter.all;
  final Set<String> _selected = {};

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  void _toggleAll(Set<String> ids) => setState(() {
        if (ids.every(_selected.contains)) {
          _selected.removeAll(ids);
        } else {
          _selected.addAll(ids);
        }
      });

  void _keeperHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text(AppStrings.keepBadgeHint),
        duration: Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));

    if (result == null) {
      return SubPageScaffold(
        title: AppStrings.duplicatePhotos,
        onBack: () => context.pop(),
        children: [
          const SubEmpty(
            asset: AppAssets.image,
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

    final exactIds = {for (final g in result.duplicateGroups) g.id};
    final groups = switch (_filter) {
      _DupFilter.all => result.allGroups,
      _DupFilter.exact => result.duplicateGroups,
      _DupFilter.similar => result.similarGroups,
    };

    // Chỉ giữ lựa chọn còn hợp lệ (mục đã xóa khỏi kết quả thì bỏ).
    final validIds = <String>{
      for (final g in result.allGroups) ...g.removable.map((i) => i.id),
    };
    final selected = _selected.where(validIds.contains).toSet();
    var selectedBytes = 0;
    for (final g in result.allGroups) {
      for (final i in g.removable) {
        if (selected.contains(i.id)) selectedBytes += i.sizeBytes ?? 0;
      }
    }
    final shownIds = <String>{
      for (final g in groups) ...g.removable.map((i) => i.id),
    };
    final reclaimable = groups.fold<int>(0, (s, g) => s + g.reclaimableBytes);
    final size = splitBytes(reclaimable);

    return SubPageScaffold.lazy(
      title: AppStrings.duplicatePhotos,
      onBack: () => context.pop(),
      action: shownIds.isEmpty
          ? null
          : SubPill(
              label: shownIds.every(selected.contains)
                  ? AppStrings.deselectAll
                  : AppStrings.selectAll,
              onTap: () => _toggleAll(shownIds),
            ),
      bottom: SubBottomBar(
        label: selected.isEmpty
            ? AppStrings.pickPhotosToDelete
            : AppStrings.deletePhotos(selected.length, formatBytes(selectedBytes)),
        onPressed: selected.isEmpty
            ? null
            : () {
                ref.read(cleanupPlanProvider.notifier).selectOnly(selected);
                context.push(AppRoutes.cleanupReview);
              },
      ),
      children: [
        SubCard(
          child: Row(
            children: [
              Expanded(
                child: SubBigStat(
                  value: size.value,
                  unit: size.unit,
                  caption: AppStrings.groupsReclaimable(groups.length),
                ),
              ),
              const SubIconTile(
                  asset: AppAssets.image, size: 48, iconSize: 22),
            ],
          ),
        ),
        _Segmented(
          value: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        if (groups.isEmpty)
          const SubEmpty(
            asset: AppAssets.image,
            title: AppStrings.dupEmptyTitle,
            body: AppStrings.noDuplicatesFound,
          ),
      ],
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return _GroupCard(
          index: i + 1,
          group: g,
          exact: exactIds.contains(g.id),
          selected: selected,
          onToggle: _toggle,
          onKeeperTap: _keeperHint,
        );
      },
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});

  final _DupFilter value;
  final ValueChanged<_DupFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      _DupFilter.all: AppStrings.filterAll,
      _DupFilter.exact: AppStrings.filterExact,
      _DupFilter.similar: AppStrings.filterSimilar,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.iconTile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final f in _DupFilter.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: f == value ? AppColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: f == value
                        ? const [
                            BoxShadow(
                              color: Color(0x1F111827),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      labels[f]!,
                      style: AppText.custom(
                        12.5,
                        FontWeight.w600,
                        f == value ? AppColors.titleInk : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.index,
    required this.group,
    required this.exact,
    required this.selected,
    required this.onToggle,
    required this.onKeeperTap,
  });

  final int index;
  final MediaGroup group;
  final bool exact;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onKeeperTap;

  @override
  Widget build(BuildContext context) {
    final items = group.items;
    return SubCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.groupTitle(index, items.length),
                  style: AppText.custom(13.5, FontWeight.w600, AppColors.titleInk),
                ),
              ),
              Text(
                '${exact ? AppStrings.filterExact : AppStrings.filterSimilar}'
                ' · ${formatShortDate(group.keeper.createdAt)}',
                style: AppText.custom(12, FontWeight.w400, AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var r = 0; r < items.length; r += 3)
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++) ...[
                    if (c > 0) const SizedBox(width: 8),
                    Expanded(
                      child: r + c < items.length
                          ? _PhotoCell(
                              item: items[r + c],
                              keeper: r + c == 0,
                              selected: selected.contains(items[r + c].id),
                              onTap: r + c == 0
                                  ? onKeeperTap
                                  : () => onToggle(items[r + c].id),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    required this.item,
    required this.keeper,
    required this.selected,
    required this.onTap,
  });

  final MediaItem item;
  final bool keeper;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = box.maxWidth;
          return GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                MediaThumbnail(
                  id: item.id,
                  width: side,
                  height: side,
                  radius: 14,
                  requestSize: 300,
                ),
                if (selected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                if (!keeper)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: SelectCheck(selected: selected, size: 22),
                  ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: keeper
                      ? _Badge(
                          text: AppStrings.keepBadge,
                          background: AppColors.surface,
                          color: AppColors.positive,
                        )
                      : (item.sizeBytes == null
                          ? const SizedBox.shrink()
                          : _Badge(
                              text: formatBytes(item.sizeBytes!),
                              background: const Color(0xA6111827),
                              color: Colors.white,
                            )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.color,
  });

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: AppText.custom(10, FontWeight.w700, color),
      ),
    );
  }
}
