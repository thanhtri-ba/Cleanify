import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/format_date.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/media_item.dart';
import '../../scan/domain/scan_models.dart';
import '../application/library_controller.dart';
import '../../../core/theme/app_tokens.dart';

// Bảng màu màn xem ảnh (Figma 127:1637), giữ cục bộ để không đổi theme chung.
const _screen = Color(0xFF111111);
const _chip = Color(0xFF1D1D1D);
const _duplicateBadge = Color(0xFF686868);
const _keepTag = Color(0xFF919191);
const _deleteTag = Color(0xFFCE2626);
const _keepGreen = Color(0xFF00905A);
const _deleteRed = Color(0xFFCE2626);
const _textPrimary = Color(0xFFFAFAFA);

/// Xem ảnh/video toàn màn hình, vuốt ngang để chuyển sang mục kế bên,
/// chụm hai ngón để phóng to. Ảnh thuộc nhóm trùng/tương tự hiện thêm
/// điều hướng giữa các bản trong nhóm và nút giữ/đánh dấu xóa.
class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, int count) {
    setState(() => _index = index);
    // Gần cuối danh sách đã nạp thì nạp thêm để vuốt tiếp không bị dừng.
    if (index >= count - 10) {
      ref.read(libraryControllerProvider.notifier).loadMore();
    }
  }

  void _goTo(int libraryIndex) {
    _pages.animateToPage(
      libraryIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(libraryControllerProvider.select((s) => s.items));
    if (items.isEmpty) return const Scaffold(backgroundColor: _screen);
    final index = _index.clamp(0, items.length - 1).toInt();
    final current = items[index];

    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    final plan = ref.watch(cleanupPlanProvider);
    final group = _findGroup(result, current.id);
    final members = group?.items ?? const <MediaItem>[];
    final memberPos = members.indexWhere((m) => m.id == current.id);

    final selected = plan?.isSelected(current.id) ?? false;
    final canMark = plan != null && !selected && plan.canSelect(current.id);
    final String? markHint = selected || canMark
        ? null
        : plan == null
            ? 'Scan first to mark photos for deletion.'
            : group != null
                ? 'Keep at least one copy in each group.'
                : 'Only photos from your last scan can be marked here.';

    final prevLib = memberPos > 0
        ? _indexOf(items, members[memberPos - 1].id)
        : -1;
    final nextLib = memberPos >= 0 && memberPos < members.length - 1
        ? _indexOf(items, members[memberPos + 1].id)
        : -1;

    void toggle() => ref.read(cleanupPlanProvider.notifier).toggleItem(current.id);

    return Scaffold(
      backgroundColor: _screen,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Photo Preview',
              subtitle: '${index + 1} of ${items.length}',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PageView.builder(
                        controller: _pages,
                        // Đang phóng to thì nhường thao tác kéo cho ảnh, không lật trang.
                        physics: _zoomed
                            ? const NeverScrollableScrollPhysics()
                            : const PageScrollPhysics(),
                        itemCount: items.length,
                        onPageChanged: (i) => _onPageChanged(i, items.length),
                        itemBuilder: (context, i) => _FullImage(
                          item: items[i],
                          onZoomChanged: (zoomed) {
                            if (zoomed != _zoomed) {
                              setState(() => _zoomed = zoomed);
                            }
                          },
                        ),
                      ),
                    ),
                    if (group != null)
                      const Positioned(
                        left: 12,
                        top: 12,
                        child: _Tag(
                          label: 'Duplicate',
                          color: _duplicateBadge,
                          radius: 100,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                    if (members.length > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: _Dots(count: members.length, active: memberPos),
                      ),
                  ],
                ),
              ),
            ),
            if (members.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Previous duplicate',
                      onTap: prevLib >= 0 ? () => _goTo(prevLib) : null,
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _chip,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${memberPos + 1} of ${members.length}',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _CircleButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Next duplicate',
                      onTap: nextLib >= 0 ? () => _goTo(nextLib) : null,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _Details(
                title: formatShortDate(current.createdAt),
                tag: selected
                    ? const _Tag(
                        label: 'Delete',
                        color: _deleteTag,
                        radius: 4,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      )
                    : const _Tag(
                        label: 'Keep',
                        color: _keepTag,
                        radius: 4,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                width: current.width,
                height: current.height,
                sizeBytes: current.sizeBytes,
                date: formatShortDate(current.createdAt),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Keep Original',
                          color: _keepGreen,
                          textColor: context.tokens.surface,
                          enabled: selected,
                          onTap: selected ? toggle : null,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Mark for deletion',
                          color: _deleteRed,
                          textColor: context.tokens.surface,
                          border: const Color(0xFF808080),
                          enabled: canMark,
                          onTap: canMark ? toggle : null,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    markHint ?? 'Nothing is deleted until you review and confirm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.tokens.textMuted,
                      fontSize: 12,
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

  static MediaGroup? _findGroup(ScanResult? result, String id) {
    if (result == null) return null;
    for (final g in [...result.duplicateGroups, ...result.similarGroups]) {
      if (g.items.any((m) => m.id == id)) return g;
    }
    return null;
  }

  static int _indexOf(List<MediaItem> items, String id) =>
      items.indexWhere((m) => m.id == id);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: AppStrings.back,
            onTap: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: context.tokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Chỗ trống giữ tiêu đề căn giữa (Figma có nút "more" chưa có chức năng).
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: _chip,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: _textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.radius,
    required this.padding,
  });

  final String label;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == active ? context.tokens.surface : const Color(0x66FFFFFF),
              ),
            ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.title,
    required this.tag,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.date,
  });

  final String title;
  final Widget tag;
  final int width;
  final int height;
  final int? sizeBytes;
  final String date;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.tokens.textMuted, fontSize: 13, height: 1.3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            tag,
          ],
        ),
        const SizedBox(height: 8),
        Text('Dimensions: $width × $height px', style: muted),
        const SizedBox(height: 2),
        Text(
          'File Size: ${sizeBytes == null ? '—' : formatBytes(sizeBytes!)}',
          style: muted,
        ),
        const SizedBox(height: 2),
        Text('Date: $date', style: muted),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.fontSize,
    this.textColor = Colors.white,
    this.border,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;
  final double fontSize;
  final Color textColor;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: border == null
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border!),
                  ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullImage extends ConsumerStatefulWidget {
  const _FullImage({required this.item, required this.onZoomChanged});

  final MediaItem item;
  final ValueChanged<bool> onZoomChanged;

  @override
  ConsumerState<_FullImage> createState() => _FullImageState();
}

class _FullImageState extends ConsumerState<_FullImage> {
  final _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(
      () => widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.02),
    );
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cạnh dài 1600px đủ nét trên màn hình điện thoại mà không đọc file gốc.
    final bytes =
        ref.watch(thumbnailProvider(ThumbnailRequest(widget.item.id, 1600)));
    return bytes.when(
      data: (data) => data == null
          ? const _Failed()
          : InteractiveViewer(
              transformationController: _transform,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  data,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                ),
              ),
            ),
      loading: () => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: context.tokens.surface),
        ),
      ),
      error: (_, __) => const _Failed(),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text(
          AppStrings.libraryLoadFailed,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
}
