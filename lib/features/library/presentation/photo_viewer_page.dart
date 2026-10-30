import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/format_date.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/media_item.dart';
import '../application/library_controller.dart';

/// Xem ảnh/video toàn màn hình, vuốt ngang để chuyển sang mục kế bên,
/// chụm hai ngón để phóng to.
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

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(libraryControllerProvider.select((s) => s.items));
    if (items.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    final index = _index.clamp(0, items.length - 1);
    final current = items[index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
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
                if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              title: formatShortDate(current.createdAt),
              position: '${index + 1} / ${items.length}',
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.position,
    required this.onClose,
  });

  final String title;
  final String position;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Color(0x00000000)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                tooltip: AppStrings.back,
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  position,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
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
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
