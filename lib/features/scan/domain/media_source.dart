import 'feature_index.dart';
import 'media_item.dart';

/// Lỗi ở mức cả thư viện (mất quyền, thư viện tạm thời không truy cập được).
/// Lỗi của từng mục riêng lẻ KHÔNG ném lỗi: trả về null để bỏ qua mục đó.
class MediaSourceException implements Exception {
  const MediaSourceException(this.message);

  final String message;

  @override
  String toString() => 'MediaSourceException: $message';
}

/// Cạnh ảnh xám dùng để tính PDQ (64x64).
const int lumaSide = 64;
const int lumaGridSize = lumaSide * lumaSide;

abstract interface class MediaSource {
  /// Tổng số ảnh + video truy cập được.
  Future<int> count();

  /// Một trang metadata, [page] bắt đầu từ 0.
  Future<List<MediaItem>> page(int page, int pageSize);

  /// Dung lượng file (byte) hoặc null nếu không đọc được.
  Future<int?> sizeOf(MediaItem item);

  /// Ảnh xám 64x64 (4096 giá trị 0..255, theo hàng) để tính PDQ, hoặc null.
  Future<List<int>?> lumaGrid(MediaItem item);

  /// Đặc trưng ORB của ảnh (dùng thumbnail), hoặc null nếu không trích được.
  Future<FeatureSet?> featureSet(MediaItem item);

  /// Luồng byte của file gốc để tính SHA-256 (đọc theo khối), hoặc null.
  Future<Stream<List<int>>?> openOriginal(MediaItem item);

  /// Giải phóng file tạm đã sinh ra khi đo (nếu có).
  Future<void> releaseCaches();
}

/// Xóa theo id. Trả về các id đã thực sự bị xóa (có thể ít hơn đầu vào nếu
/// người dùng từ chối hộp thoại xác nhận của hệ điều hành).
abstract interface class MediaDeleter {
  Future<List<String>> delete(List<String> ids);
}
