import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../application/scan_providers.dart';

/// Ảnh thu nhỏ của một mục trong thư viện. Khi đang tải hoặc không tải được
/// thì hiện ô nền nhạt, không báo lỗi ra giao diện.
/// [width] null nghĩa là giãn theo chiều rộng cha.
class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({
    super.key,
    required this.id,
    this.width,
    this.height = 88,
    this.radius = 12,
    this.requestSize = 240,
  });

  final String id;
  final double? width;
  final double height;
  final double radius;

  /// Cạnh ảnh yêu cầu (px), lớn hơn kích thước hiển thị để nét trên màn mật độ cao.
  final int requestSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref
        .watch(thumbnailProvider(ThumbnailRequest(id, requestSize)))
        .valueOrNull;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            child: bytes == null
                ? ColoredBox(
                    key: const ValueKey('placeholder'),
                    color: context.tokens.chip,
                  )
                : Image.memory(
                    bytes,
                    key: const ValueKey('image'),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
          ),
        ),
      ),
    );
  }
}
