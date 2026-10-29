import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart';

import '../domain/media_item.dart';
import '../domain/media_source.dart';

/// Nguồn media thật dựa trên `photo_manager`.
///
/// Lưu ý đã biết (cần kiểm tra trên máy thật):
/// - [sizeOf] dùng `originFile`. Trên iOS đây có thể xuất file ra thư mục tạm
///   (và có thể kích hoạt tải iCloud), nên [releaseCaches] được gọi sau mỗi
///   giai đoạn để dọn.
/// - Ảnh chụp màn hình: iOS dùng bit subtype (1 << 2), Android dùng đường dẫn
///   thư mục chứa "screenshot".
class PhotoManagerMediaSource implements MediaSource {
  static const int _iosScreenshotSubtype = 1 << 2;

  AssetPathEntity? _root;
  final Map<String, AssetEntity> _entities = {};

  Future<AssetPathEntity?> _library() async {
    final cached = _root;
    if (cached != null) return cached;
    try {
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.common,
      );
      if (paths.isEmpty) return null;
      return _root = paths.first;
    } catch (e) {
      throw MediaSourceException('Cannot open photo library: $e');
    }
  }

  @override
  Future<int> count() async {
    final root = await _library();
    if (root == null) return 0;
    try {
      return await root.assetCountAsync;
    } catch (e) {
      throw MediaSourceException('Cannot read photo library: $e');
    }
  }

  @override
  Future<List<MediaItem>> page(int page, int pageSize) async {
    final root = await _library();
    if (root == null) return const [];
    try {
      final entities = await root.getAssetListPaged(page: page, size: pageSize);
      final items = <MediaItem>[];
      for (final entity in entities) {
        final kind = switch (entity.type) {
          AssetType.image => MediaKind.image,
          AssetType.video => MediaKind.video,
          _ => null,
        };
        if (kind == null) continue;
        _entities[entity.id] = entity;
        items.add(
          MediaItem(
            id: entity.id,
            kind: kind,
            width: entity.width,
            height: entity.height,
            createdAt: entity.createDateTime,
            isScreenshot: _isScreenshot(entity),
          ),
        );
      }
      return items;
    } catch (e) {
      throw MediaSourceException('Cannot read photo library: $e');
    }
  }

  static bool _isScreenshot(AssetEntity entity) {
    if ((entity.subtype & _iosScreenshotSubtype) != 0) return true;
    final path = entity.relativePath;
    return path != null && path.toLowerCase().contains('screenshot');
  }

  @override
  Future<int?> sizeOf(MediaItem item) async {
    final entity = _entities[item.id];
    if (entity == null) return null;
    try {
      final file = await entity.originFile;
      if (file == null) return null;
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<int>?> lumaGrid(MediaItem item) async {
    final entity = _entities[item.id];
    if (entity == null) return null;
    try {
      final bytes = await entity.thumbnailDataWithSize(
        const ThumbnailSize(32, 32),
        quality: 70,
      );
      if (bytes == null) return null;
      return await _decodeLuma(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<List<int>?> _decodeLuma(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: lumaSquareSize,
      targetHeight: lumaSquareSize,
    );
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data == null) return null;
        const pixels = lumaSquareSize * lumaSquareSize;
        final luma = <int>[];
        for (var i = 0; i < pixels; i++) {
          final r = data.getUint8(i * 4);
          final g = data.getUint8(i * 4 + 1);
          final b = data.getUint8(i * 4 + 2);
          luma.add((0.299 * r + 0.587 * g + 0.114 * b).round());
        }
        return luma;
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  @override
  Future<void> releaseCaches() => PhotoManager.clearFileCache();
}

class PhotoManagerMediaDeleter implements MediaDeleter {
  const PhotoManagerMediaDeleter();

  @override
  Future<List<String>> delete(List<String> ids) =>
      PhotoManager.editor.deleteWithIds(ids);
}
