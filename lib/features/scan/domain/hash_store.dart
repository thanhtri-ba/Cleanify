import 'dart:typed_data';

/// Kết quả băm đã lưu của một ảnh. Dùng lại khi ảnh chưa đổi.
class StoredHash {
  const StoredHash({
    required this.id,
    required this.width,
    required this.height,
    required this.modifiedAtMs,
    required this.fileSize,
    required this.sha256,
    required this.pdq,
    required this.pdqQuality,
    this.features,
  });

  final String id;
  final int width;
  final int height;
  final int modifiedAtMs;
  final int fileSize;

  /// SHA-256 của file gốc, dạng hex.
  final String sha256;

  /// PDQ 256 bit (32 byte).
  final Uint8List pdq;
  final int pdqQuality;

  /// Đặc trưng ORB đã gói (FeatureSet.pack), hoặc null nếu chưa trích.
  final Uint8List? features;
}

/// Nơi lưu hash theo từng ảnh để các lần quét sau chỉ tính lại ảnh mới/đã đổi.
abstract interface class HashStore {
  Future<Map<String, StoredHash>> loadAll();

  Future<void> saveAll(List<StoredHash> rows);

  /// Xoá các dòng có id không còn trong thư viện.
  Future<void> retainOnly(Set<String> ids);
}
