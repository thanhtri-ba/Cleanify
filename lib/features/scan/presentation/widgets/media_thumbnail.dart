import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/scan_providers.dart';

/// Ảnh thu nhỏ của một mục trong thư viện. Khi đang tải hoặc không tải được
/// thì hiện ô nền nhạt, không báo lỗi ra giao diện.
class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({
    super.key,
    required this.id,
    this.size = 88,
    this.radius = 12,
  });

  final String id;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Yêu cầu ảnh gấp đôi kích thước hiển thị để nét trên màn mật độ cao.
    final request = ThumbnailRequest(id, (size * 2).round());
    final bytes = ref.watch(thumbnailProvider(request)).valueOrNull;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: bytes == null
            ? const ColoredBox(color: AppColors.chip)
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                excludeFromSemantics: true,
              ),
      ),
    );
  }
}
