import 'media_item.dart';

/// Lỗi ở mức cả thư viện (mất quyền, thư viện tạm thời không truy cập được).
/// Lỗi của từng mục riêng lẻ KHÔNG ném lỗi: trả về null để bỏ qua mục đó.
class MediaSourceException implements Exception {
  const MediaSourceException(this.message);

  final String message;

  @override
  String toString() => 'MediaSourceException: $message';
}

/// Số ô của lưới độ sáng dùng tính dHash (9 cột x 8 hàng).
const int lumaGridWidth = 9;
const int lumaGridHeight = 8;
const int lumaGridSize = lumaGridWidth * lumaGridHeight;

abstract interface class MediaSource {
  /// Tổng số ảnh + video truy cập được.
  Future<int> count();

  /// Một trang metadata, [page] bắt đầu từ 0.
  Future<List<MediaItem>> page(int page, int pageSize);

  /// Dung lượng file (byte) hoặc null nếu không đọc được.
  Future<int?> sizeOf(MediaItem item);

  /// Lưới độ sáng 9x8 (72 giá trị 0..255) của ảnh thu nhỏ, hoặc null.
  Future<List<int>?> lumaGrid(MediaItem item);

  /// Giải phóng file tạm đã sinh ra khi đo (nếu có).
  Future<void> releaseCaches();
}

/// Xóa theo id. Trả về các id đã thực sự bị xóa (có thể ít hơn đầu vào nếu
/// người dùng từ chối hộp thoại xác nhận của hệ điều hành).
abstract interface class MediaDeleter {
  Future<List<String>> delete(List<String> ids);
}
