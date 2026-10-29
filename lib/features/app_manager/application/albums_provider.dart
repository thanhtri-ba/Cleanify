import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

/// Một album ảnh/video trong thư viện (thường là nguồn: WhatsApp, Telegram...).
class AlbumInfo {
  const AlbumInfo({required this.name, required this.count});

  final String name;
  final int count;
}

abstract interface class AlbumSource {
  Future<List<AlbumInfo>> albums();
}

class PhotoManagerAlbumSource implements AlbumSource {
  const PhotoManagerAlbumSource();

  @override
  Future<List<AlbumInfo>> albums() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: false,
    );
    final out = <AlbumInfo>[];
    for (final p in paths) {
      // Bỏ album "tất cả" vì trùng với toàn bộ thư viện.
      if (p.isAll) continue;
      final count = await p.assetCountAsync;
      if (count > 0) out.add(AlbumInfo(name: p.name, count: count));
    }
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }
}

final albumSourceProvider =
    Provider<AlbumSource>((ref) => const PhotoManagerAlbumSource());

final albumsProvider = FutureProvider.autoDispose<List<AlbumInfo>>(
  (ref) => ref.watch(albumSourceProvider).albums(),
);
