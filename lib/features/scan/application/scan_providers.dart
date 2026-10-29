import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/device_storage.dart';
import '../data/photo_manager_media_source.dart';
import '../domain/device_storage.dart';
import '../domain/media_source.dart';
import '../domain/scan_models.dart';

final mediaSourceProvider =
    Provider<MediaSource>((ref) => PhotoManagerMediaSource());

final mediaDeleterProvider =
    Provider<MediaDeleter>((ref) => const PhotoManagerMediaDeleter());

final deviceStorageSourceProvider =
    Provider<DeviceStorageSource>((ref) => const DiskSpaceStorageSource());

/// Cấu hình quét. Màn Scan Preferences sẽ ghi đè provider này.
final scanConfigProvider = Provider<ScanConfig>((ref) => const ScanConfig());

final deviceStorageProvider = FutureProvider.autoDispose<DeviceStorage>(
  (ref) => ref.watch(deviceStorageSourceProvider).read(),
);

class ThumbnailRequest {
  const ThumbnailRequest(this.id, this.size);

  final String id;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is ThumbnailRequest && other.id == id && other.size == size;

  @override
  int get hashCode => Object.hash(id, size);
}

/// Ảnh thu nhỏ để hiển thị; null nếu không tải được.
final thumbnailProvider =
    FutureProvider.family<Uint8List?, ThumbnailRequest>((ref, request) async {
  try {
    final entity = await AssetEntity.fromId(request.id);
    return await entity?.thumbnailDataWithSize(
      ThumbnailSize.square(request.size),
    );
  } catch (_) {
    return null;
  }
});

/// Phân bổ dung lượng theo nhóm. Chưa có nguồn dữ liệu nên luôn null; khi có
/// (vd. qua platform channel) chỉ cần thay provider này.
final storageBreakdownProvider = Provider<StorageBreakdown?>((ref) => null);
