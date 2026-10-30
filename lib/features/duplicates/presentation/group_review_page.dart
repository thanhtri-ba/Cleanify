import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../activity/presentation/activity_format.dart';
import '../../scan/application/cleanup_controller.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/domain/media_item.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';
import '../../../core/theme/app_tokens.dart';

/// Review Group (Figma 127:528): giữ/xóa từng ảnh trong một nhóm trùng/tương tự.
/// Mặc định xóa mọi ảnh trừ ảnh tốt nhất (ảnh đầu nhóm). Xác nhận qua sheet
/// (127:431) rồi chạy cùng luồng dọn như Review Cleanup.
class GroupReviewPage extends ConsumerStatefulWidget {
  const GroupReviewPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupReviewPage> createState() => _GroupReviewPageState();
}

class _GroupReviewPageState extends ConsumerState<GroupReviewPage> {
  int _focus = 0;

  /// Id các ảnh sẽ xóa. Khởi tạo một lần từ nhóm đầu tiên.
  Set<String>? _remove;

  void _setRemove(String id, bool remove) {
    setState(() {
      if (remove) {
        _remove!.add(id);
      } else {
        _remove!.remove(id);
      }
    });
  }

  Future<void> _confirm(List<MediaItem> removing, int bytes) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteConfirmSheet(removing: removing, bytes: bytes),
    );
    if (ok != true || !mounted) return;
    ref.read(cleanupPlanProvider.notifier).selectOnly(_remove!);
    ref.read(cleanupControllerProvider.notifier).start();
    context.pushReplacement(AppRoutes.cleanupProgress);
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    final group = _findGroup(result, widget.groupId);
    if (group == null || group.items.length < 2) {
      return _NotFound(onBack: () => context.pop());
    }

    final items = group.items;
    _remove ??= {for (final m in group.removable) m.id};
    final remove = _remove!;
    final focusIndex = _focus.clamp(0, items.length - 1).toInt();
    final focus = items[focusIndex];
    final best = items.first;

    final groups = result!.allGroups;
    final groupNumber = groups.indexWhere((g) => g.id == group.id) + 1;

    final removing = [for (final m in items) if (remove.contains(m.id)) m];
    final removeBytes = removing.fold<int>(0, (s, m) => s + (m.sizeBytes ?? 0));
    final focusRemoved = remove.contains(focus.id);

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Group $groupNumber of ${groups.length}',
                        style: AppText.custom(13, FontWeight.w400, context.tokens.textPrimary),
                      ),
                      Text(
                        'Your choices',
                        style: AppText.custom(11, FontWeight.w400, context.tokens.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FocusCard(
                    item: focus,
                    isBest: focus.id == best.id,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${items.length} similar photos',
                        style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary),
                      ),
                      Text(
                        '${focusIndex + 1} of ${items.length}',
                        style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _Thumb(
                            item: items[i],
                            focused: i == focusIndex,
                            removed: remove.contains(items[i].id),
                            onTap: () => setState(() => _focus = i),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DecisionSwitch(
                    removed: focusRemoved,
                    onKeep: () => _setRemove(focus.id, false),
                    onRemove: () => _setRemove(focus.id, true),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSvg(AppAssets.sparkles, size: 16, color: context.tokens.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Best quality is only a suggestion. Nothing is removed until you confirm.',
                          style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary,
                              lineHeight: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                border: Border(top: BorderSide(color: context.tokens.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    removing.isEmpty
                        ? 'Keep all photos in this group'
                        : 'Remove ${removing.length} photos · Save ${formatBytes(removeBytes)}',
                    textAlign: TextAlign.center,
                    style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary,
                        lineHeight: 20),
                  ),
                  const SizedBox(height: 10),
                  _Button(
                    label: 'Confirm Selection',
                    filled: true,
                    onPressed: removing.isEmpty
                        ? null
                        : () => _confirm(removing, removeBytes),
                  ),
                  const SizedBox(height: 4),
                  _Button(
                    label: 'Skip Group',
                    filled: false,
                    onPressed: () => context.pop(),
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

MediaGroup? _findGroup(ScanResult? result, String id) {
  if (result == null) return null;
  for (final g in result.allGroups) {
    if (g.id == id) return g;
  }
  return null;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: Material(
              color: context.tokens.surfaceMuted,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: AppSvg(AppAssets.chevronLeft, size: 18)),
                ),
              ),
            ),
          ),
          Text(
            'Review Group',
            style: AppText.custom(18, FontWeight.w600, context.tokens.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.item, required this.isBest});

  final MediaItem item;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final mp = (item.width * item.height / 1000000).round();
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 212,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MediaThumbnail(
                    id: item.id,
                    height: 212,
                    width: double.infinity,
                    radius: 0,
                    requestSize: 800,
                  ),
                ),
                if (isBest)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 30,
                      decoration: BoxDecoration(
                        color: context.tokens.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppSvg(AppAssets.sparkles, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Best quality',
                            style: AppText.custom(12, FontWeight.w600, context.tokens.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.width} × ${item.height}',
                        style: AppText.custom(12, FontWeight.w600, context.tokens.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$mp MP · ${formatBytes(item.sizeBytes ?? 0)}',
                        style: AppText.custom(11, FontWeight.w400, context.tokens.textSecondary),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        shortDate(item.createdAt),
                        style: AppText.custom(12, FontWeight.w500, context.tokens.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Taken at ${clock(item.createdAt)}',
                        style: AppText.custom(11, FontWeight.w400, context.tokens.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.item,
    required this.focused,
    required this.removed,
    required this.onTap,
  });

  final MediaItem item;
  final bool focused;
  final bool removed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 78,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused ? Color(0xFF676767) : context.tokens.border,
                width: focused ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MediaThumbnail(id: item.id, height: 72, radius: 10),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: Center(
                    child: Container(
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: removed ? Color(0xFF1B1B1B) : context.tokens.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        removed ? '− Remove' : '✓ Keep',
                        style: AppText.custom(10, FontWeight.w600,
                            removed ? Colors.white : context.tokens.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatBytes(item.sizeBytes ?? 0),
            style: AppText.custom(10, FontWeight.w400, context.tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DecisionSwitch extends StatelessWidget {
  const _DecisionSwitch({
    required this.removed,
    required this.onKeep,
    required this.onRemove,
  });

  final bool removed;
  final VoidCallback onKeep;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Keep',
              selected: !removed,
              onTap: onKeep,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              label: 'Remove',
              selected: removed,
              onTap: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.tokens.surface : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: Color(0xFF676767))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: AppText.custom(14, selected ? FontWeight.w600 : FontWeight.w500,
                selected ? context.tokens.textPrimary : context.tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final height = filled ? 52.0 : 44.0;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: filled ? Color(0xFF676767) : context.tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: AppText.custom(14, FontWeight.w600,
                    filled ? Colors.white : context.tokens.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet xác nhận xóa (Figma 127:431). Trả true khi người dùng bấm xóa.
class _DeleteConfirmSheet extends StatelessWidget {
  const _DeleteConfirmSheet({required this.removing, required this.bytes});

  final List<MediaItem> removing;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    final count = removing.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC6C6C6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Remove $count ${count == 1 ? 'photo' : 'photos'}?',
            style: AppText.custom(24, FontWeight.w600, context.tokens.textPrimary,
                lineHeight: 30),
          ),
          const SizedBox(height: 10),
          Text(
            'This will free up ${formatBytes(bytes)}. Removed photos move to Recently Deleted and can be restored for a limited time.',
            style: AppText.custom(14, FontWeight.w400, context.tokens.textPrimary,
                lineHeight: 21),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < removing.length && i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MediaThumbnail(
                            id: removing[i].id,
                            height: 80,
                            radius: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatBytes(removing[i].sizeBytes ?? 0),
                        style: AppText.custom(11, FontWeight.w400, context.tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Material(
            color: const Color(0xFF3C3C3C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).pop(true),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: Text(
                    'Remove $count ${count == 1 ? 'Photo' : 'Photos'}',
                    style: AppText.custom(14, FontWeight.w600, Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: context.tokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.tokens.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).pop(false),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: Text(
                    'Cancel',
                    style: AppText.custom(14, FontWeight.w600, context.tokens.textPrimary),
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

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: onBack),
            Expanded(
              child: Center(
                child: Text(
                  AppStrings.dupNotScannedTitle,
                  style: AppText.custom(18, FontWeight.w600, context.tokens.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
