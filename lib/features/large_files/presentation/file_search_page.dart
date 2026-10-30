import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/app_svg.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/domain/media_item.dart';
import '../../../core/theme/app_tokens.dart';

const _ink = Color(0xFF181818);
const _muted = Color(0xFF727272);

/// Search files (Figma 127:1884 / 127:1905 / 127:1959), tìm trong danh sách
/// file lớn của lần quét gần nhất. Ảnh/video không có tên file trong app nên
/// tìm theo ngày, loại, kích thước và độ phân giải.
class FileSearchPage extends ConsumerStatefulWidget {
  const FileSearchPage({super.key});

  @override
  ConsumerState<FileSearchPage> createState() => _FileSearchPageState();
}

class _FileSearchPageState extends ConsumerState<FileSearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _haystack(MediaItem m) => [
        m.kind == MediaKind.video ? 'video' : 'photo',
        formatShortDate(m.createdAt),
        '${m.width} x ${m.height}',
        if (m.sizeBytes != null) formatBytes(m.sizeBytes!),
      ].join(' ').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final result =
        ref.watch(scanControllerProvider.select((s) => s.outcome?.result));
    final large = result?.largeVideos ?? const <MediaItem>[];
    final q = _query.trim().toLowerCase();
    final matches = q.isEmpty
        ? const <MediaItem>[]
        : large.where((m) => _haystack(m).contains(q)).toList();

    final Widget body;
    if (q.isEmpty) {
      body = const _EmptyState(
        title: 'Search files',
        body:
            'Type a date, file type, size, or dimensions to find matching files in this list.',
      );
    } else if (result == null) {
      body = const _EmptyState(
        title: 'No scan results yet',
        body: 'Scan your storage first to search large files.',
      );
    } else if (matches.isEmpty) {
      body = const _EmptyState(
        title: 'No matching files',
        body:
            'Try another search term or clear the current query to browse the full list.',
      );
    } else {
      body = ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              const Text(
                'Matching results',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const Spacer(),
              Text(
                '${matches.length} matches',
                style: TextStyle(fontSize: 11, color: context.tokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final m in matches) _ResultRow(item: m),
        ],
      );
    }

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.storage),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: AppSvg(AppAssets.chevronLeft,
                            size: 23, color: context.tokens.textPrimary),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Search files',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: context.tokens.border),
                      ),
                      child: Text(
                        'In Large Files',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.tokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          AppSvg(AppAssets.search, size: 18, color: context.tokens.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search files',
                hintStyle: TextStyle(color: context.tokens.textSecondary, fontSize: 15),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: TextStyle(fontSize: 15, color: context.tokens.textPrimary),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.tokens.border),
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: _ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.tokens.border),
            ),
            child: const Icon(Icons.search_rounded, size: 28, color: _ink),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.43, color: context.tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.kind == MediaKind.video;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.tokens.border),
            ),
            child: Icon(
              isVideo ? Icons.videocam_outlined : Icons.image_outlined,
              size: 18,
              color: _ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatShortDate(item.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isVideo ? 'Video' : 'Photo'} · ${item.width} × ${item.height} px',
                  style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
                ),
              ],
            ),
          ),
          if (item.sizeBytes != null)
            Text(
              formatBytes(item.sizeBytes!),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
        ],
      ),
    );
  }
}
