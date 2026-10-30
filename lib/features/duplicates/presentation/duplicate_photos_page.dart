import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';

enum _DupFilter { all, exact, similar }

/// Photo Cleaner theo Figma node 127:1423. Duyệt từng nhóm ảnh trùng/tương tự,
/// chọn nhóm muốn dọn. Bản đầu tiên của mỗi nhóm luôn được giữ lại.
/// Xóa đi qua Review Cleanup.
class DuplicatePhotosPage extends ConsumerStatefulWidget {
  const DuplicatePhotosPage({super.key});

  @override
  ConsumerState<DuplicatePhotosPage> createState() =>
      _DuplicatePhotosPageState();
}

class _DuplicatePhotosPageState extends ConsumerState<DuplicatePhotosPage> {
  _DupFilter _filter = _DupFilter.all;
  final Set<String> _selected = {};

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
      return Scaffold(
        backgroundColor: context.tokens.surface,
        body: SafeArea(
          child: Column(
            children: [
              _Header(title: AppStrings.duplicatePhotos, onBack: () => context.pop()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dupNotScannedTitle,
                        textAlign: TextAlign.center,
                        style: AppText.custom(18, FontWeight.w600, context.tokens.textPrimary,
                            lineHeight: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.dupNotScannedBody,
                        textAlign: TextAlign.center,
                        style: AppText.custom(14, FontWeight.w400,
                            context.tokens.textSecondary,
                            lineHeight: 20),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: AppStrings.scanNowShort,
                        shadows: const [],
                        onPressed: () => startScanFlow(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final canReview = selected.isNotEmpty;

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: AppStrings.duplicatePhotos,
              onBack: () => context.pop(),
              actionLabel: shownIds.isEmpty
                  ? null
                  : shownIds.every(selected.contains)
                      ? AppStrings.deselectAll
                      : AppStrings.selectAll,
              onAction: shownIds.isEmpty
                  ? null
                  : () => _toggleAll(shownIds),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${shownIds.length}',
                          style: AppText.custom(24, FontWeight.w600,
                              context.tokens.textSecondary,
                              lineHeight: 30, letterSpacing: -0.6),
                        ),
                        TextSpan(
                          text: ' similar photos found',
                          style: AppText.custom(24, FontWeight.w600,
                              context.tokens.textPrimary,
                              lineHeight: 30, letterSpacing: -0.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review your photos and free up space.',
                    style: AppText.custom(14, FontWeight.w400,
                        context.tokens.textSecondary,
                        lineHeight: 20),
                  ),
                  const SizedBox(height: 16),
                  _SaveCard(bytes: reclaimable),
                  const SizedBox(height: 16),
                  _Filters(
                    value: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: 14),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        AppStrings.noDuplicatesFound,
                        textAlign: TextAlign.center,
                        style: AppText.custom(14, FontWeight.w400,
                            context.tokens.textCaption,
                            lineHeight: 20),
                      ),
                    ),
                  for (var i = 0; i < groups.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _GroupCard(
                      index: i + 1,
                      group: groups[i],
                      exact: exactIds.contains(groups[i].id),
                      selected: selected,
                      onToggle: () =>
                          _toggleAll({for (final m in groups[i].removable) m.id}),
                      onKeeperTap: _keeperHint,
                    ),
                    _ReviewLink(groupId: groups[i].id),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 12),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                border: Border(top: BorderSide(color: Color(0xF2E8E8E8))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.tokens.borderSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Selected storage:',
                        style: AppText.custom(14, FontWeight.w400,
                            context.tokens.textSecondary,
                            lineHeight: 20),
                      ),
                      const Spacer(),
                      Text(
                        formatBytes(selectedBytes),
                        style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary,
                            lineHeight: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: canReview ? 1 : 0.4,
                    child: Material(
                      color: FlowColors.progress,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canReview
                            ? () {
                                ref
                                    .read(cleanupPlanProvider.notifier)
                                    .selectOnly(selected);
                                context.push(AppRoutes.cleanupReview);
                              }
                            : null,
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Review Selected',
                                style: AppText.custom(14, FontWeight.w600,
                                    Colors.white,
                                    lineHeight: 18, letterSpacing: 0.14),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final VoidCallback onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Material(
              color: context.tokens.iconTile,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: AppSvg(AppAssets.chevronLeft,
                        size: 14, color: context.tokens.textPrimary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.custom(18, FontWeight.w600, context.tokens.textPrimary,
                    lineHeight: 24, letterSpacing: -0.18),
              ),
            ),
            SizedBox(
              width: 72,
              child: actionLabel == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onAction,
                        child: Text(
                          actionLabel!,
                          style: AppText.custom(14, FontWeight.w500,
                              context.tokens.textPrimary,
                              lineHeight: 20),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveCard extends StatelessWidget {
  const _SaveCard({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.tokens.iconTile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x94E8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0x26676767),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome,
                size: 18, color: context.tokens.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save up to ${formatBytes(bytes)}',
                  style: AppText.custom(16, FontWeight.w600, context.tokens.textPrimary,
                      lineHeight: 24, letterSpacing: -0.08),
                ),
                Text(
                  'Potential storage savings',
                  style: AppText.custom(12, FontWeight.w500,
                      context.tokens.textSecondary,
                      lineHeight: 16, letterSpacing: 0.12),
                ),
              ],
            ),
          ),
          AppSvg(AppAssets.chevronRight,
              size: 10, color: context.tokens.textPrimary),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.value, required this.onChanged});

  final _DupFilter value;
  final ValueChanged<_DupFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_DupFilter.all, 'All'),
      (_DupFilter.exact, 'Duplicates'),
      (_DupFilter.similar, 'Similar'),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (f, label) in items) ...[
            Center(
              child: GestureDetector(
                onTap: () => onChanged(f),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
                  decoration: BoxDecoration(
                    color: f == value ? FlowColors.progress : context.tokens.surface,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                        color: f == value
                            ? FlowColors.progress
                            : context.tokens.iconTile),
                  ),
                  child: Text(
                    label,
                    style: AppText.custom(14, FontWeight.w600,
                        f == value ? Colors.white : context.tokens.textPrimary,
                        lineHeight: 18, letterSpacing: 0.14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
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
  final VoidCallback onToggle;
  final VoidCallback onKeeperTap;

  @override
  Widget build(BuildContext context) {
    final ids = {for (final m in group.removable) m.id};
    final checked = ids.isNotEmpty && ids.every(selected.contains);
    final count = group.items.length;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A202020),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: checked ? FlowColors.progress : context.tokens.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: checked
                            ? FlowColors.progress
                            : context.tokens.borderSoft,
                        width: 2),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exact ? 'Duplicates $index' : 'Similar $index',
                      style: AppText.custom(16, FontWeight.w600, context.tokens.textPrimary,
                          lineHeight: 24, letterSpacing: -0.08),
                    ),
                    Text(
                      '$count similar photos · ${formatBytes(group.reclaimableBytes)}',
                      style: AppText.custom(12, FontWeight.w500,
                          context.tokens.textSecondary,
                          lineHeight: 16, letterSpacing: 0.12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (i, m) in group.items.take(3).indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 97,
                    child: Stack(
                      children: [
                        MediaThumbnail(
                          id: m.id,
                          width: double.infinity,
                          height: 97,
                          radius: 10,
                        ),
                        if (m.id == group.keeper.id)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: GestureDetector(
                              onTap: onKeeperTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xBF303030),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BEST',
                                  style: AppText.custom(9, FontWeight.w400,
                                      Colors.white,
                                      lineHeight: 13.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Mở Review Group để giữ/xóa từng ảnh của nhóm.
class _ReviewLink extends StatelessWidget {
  const _ReviewLink({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.push(
          '${AppRoutes.groupReview}?id=${Uri.encodeQueryComponent(groupId)}',
        ),
        child: Text(
          'Review group',
          style: AppText.custom(13, FontWeight.w600, FlowColors.progress),
        ),
      ),
    );
  }
}
