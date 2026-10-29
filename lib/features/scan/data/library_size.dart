import 'package:photo_manager/photo_manager.dart';

/// Tổng dung lượng file gốc của thư viện, dùng cho giả lập dung lượng trên
/// simulator. Kết quả được nhớ theo số mục: chỉ đo lại khi số ảnh/video đổi.
class LibrarySizer {
  static const int _pageSize = 500;

  int? _count;
  int _bytes = 0;

  Future<int> bytes() async {
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
    );
    if (paths.isEmpty) return 0;
    final root = paths.first;
    final count = await root.assetCountAsync;
    if (count == _count) return _bytes;

    var total = 0;
    for (var page = 0; page * _pageSize < count; page++) {
      final assets = await root.getAssetListPaged(page: page, size: _pageSize);
      for (final asset in assets) {
        try {
          final file = await asset.originFile;
          if (file != null) total += await file.length();
        } catch (_) {
          // Mục không đọc được thì bỏ qua, giống bộ quét.
        }
      }
      await PhotoManager.clearFileCache();
    }
    _count = count;
    _bytes = total;
    return total;
  }
}
