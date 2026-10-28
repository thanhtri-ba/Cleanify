enum MediaKind { image, video }

/// Metadata của một ảnh/video trong thư viện (không chứa nội dung).
class MediaItem {
  const MediaItem({
    required this.id,
    required this.kind,
    required this.width,
    required this.height,
    required this.createdAt,
    this.isScreenshot = false,
    this.sizeBytes,
  });

  final String id;
  final MediaKind kind;
  final int width;
  final int height;
  final DateTime createdAt;
  final bool isScreenshot;

  /// Dung lượng file; null khi chưa đo hoặc không đọc được (vd. còn trên iCloud).
  final int? sizeBytes;

  int get pixels => width * height;

  MediaItem withSize(int bytes) => MediaItem(
        id: id,
        kind: kind,
        width: width,
        height: height,
        createdAt: createdAt,
        isScreenshot: isScreenshot,
        sizeBytes: bytes,
      );

  @override
  bool operator ==(Object other) => other is MediaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MediaItem($id)';
}
