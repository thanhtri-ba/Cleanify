import 'media_item.dart';

enum ScanCategory { duplicates, similar, largeVideos, screenshots }

enum CategoryStatus { pending, scanning, done }

/// Nhóm ảnh trùng/tương tự. Phần tử đầu tiên là bản nên giữ.
class MediaGroup {
  MediaGroup({required this.id, required List<MediaItem> items})
      : items = List.unmodifiable(items),
        assert(items.length >= 2, 'Một nhóm cần ít nhất 2 mục');

  final String id;
  final List<MediaItem> items;

  MediaItem get keeper => items.first;
  Iterable<MediaItem> get removable => items.skip(1);

  int get reclaimableBytes =>
      removable.fold(0, (sum, item) => sum + (item.sizeBytes ?? 0));
}

/// Kết quả quét. Chỉ các danh mục trong [completed] mới có dữ liệu hợp lệ.
class ScanResult {
  const ScanResult({
    this.duplicateGroups = const [],
    this.similarGroups = const [],
    this.largeVideos = const [],
    this.screenshots = const [],
    this.completed = const {},
  });

  final List<MediaGroup> duplicateGroups;
  final List<MediaGroup> similarGroups;
  final List<MediaItem> largeVideos;
  final List<MediaItem> screenshots;
  final Set<ScanCategory> completed;

  /// Mọi nhóm (trùng + tương tự), nhóm tiết kiệm nhiều nhất lên đầu.
  List<MediaGroup> get allGroups => [...duplicateGroups, ...similarGroups]
    ..sort((a, b) => b.reclaimableBytes.compareTo(a.reclaimableBytes));

  List<MediaGroup> groupsOf(ScanCategory category) {
    switch (category) {
      case ScanCategory.duplicates:
        return duplicateGroups;
      case ScanCategory.similar:
        return similarGroups;
      case ScanCategory.largeVideos:
      case ScanCategory.screenshots:
        return const [];
    }
  }

  /// Mọi mục thuộc danh mục (với nhóm: gồm cả bản nên giữ).
  List<MediaItem> itemsOf(ScanCategory category) {
    switch (category) {
      case ScanCategory.duplicates:
        return [for (final g in duplicateGroups) ...g.items];
      case ScanCategory.similar:
        return [for (final g in similarGroups) ...g.items];
      case ScanCategory.largeVideos:
        return largeVideos;
      case ScanCategory.screenshots:
        return screenshots;
    }
  }

  /// Số mục hiển thị cho danh mục.
  int count(ScanCategory category) => itemsOf(category).length;

  /// Dung lượng có thể giải phóng của danh mục.
  int bytes(ScanCategory category) {
    switch (category) {
      case ScanCategory.duplicates:
        return duplicateGroups.fold(0, (s, g) => s + g.reclaimableBytes);
      case ScanCategory.similar:
        return similarGroups.fold(0, (s, g) => s + g.reclaimableBytes);
      case ScanCategory.largeVideos:
        return largeVideos.fold(0, (s, i) => s + (i.sizeBytes ?? 0));
      case ScanCategory.screenshots:
        return screenshots.fold(0, (s, i) => s + (i.sizeBytes ?? 0));
    }
  }

  int get totalBytes => ScanCategory.values.fold(0, (sum, c) => sum + bytes(c));

  bool get isEmpty => ScanCategory.values.every((c) => count(c) == 0);

  /// Bản kết quả sau khi các mục [removed] đã bị xóa khỏi thư viện.
  /// Nhóm còn dưới 2 mục thì bỏ; bản nên giữ được chọn lại nếu bị xóa.
  ScanResult without(Set<String> removed) {
    List<MediaGroup> trim(List<MediaGroup> groups) {
      final out = <MediaGroup>[];
      for (final g in groups) {
        final rest = g.items.where((i) => !removed.contains(i.id)).toList();
        if (rest.length >= 2) out.add(MediaGroup(id: g.id, items: rest));
      }
      return out;
    }

    List<MediaItem> keep(List<MediaItem> items) =>
        items.where((i) => !removed.contains(i.id)).toList();

    return ScanResult(
      duplicateGroups: trim(duplicateGroups),
      similarGroups: trim(similarGroups),
      largeVideos: keep(largeVideos),
      screenshots: keep(screenshots),
      completed: completed,
    );
  }
}

class ScanProgress {
  const ScanProgress({
    required this.statuses,
    required this.itemsChecked,
    required this.total,
    required this.fraction,
    required this.estimatedBytes,
  });

  factory ScanProgress.initial() => ScanProgress(
        statuses: {
          for (final c in ScanCategory.values) c: CategoryStatus.scanning,
        },
        itemsChecked: 0,
        total: 0,
        fraction: 0,
        estimatedBytes: 0,
      );

  final Map<ScanCategory, CategoryStatus> statuses;
  final int itemsChecked;
  final int total;

  /// 0..1
  final double fraction;
  final int estimatedBytes;

  int get percent => (fraction * 100).floor();

  /// Số mục đã xử lý ước tính theo tiến độ chung.
  int get processedItems => (total * fraction).round().clamp(0, total).toInt();
}

enum ScanEnd { completed, interrupted, cancelled }

class ScanOutcome {
  const ScanOutcome({required this.end, required this.result, this.error});

  final ScanEnd end;
  final ScanResult result;
  final String? error;

  bool get hasResults => result.completed.isNotEmpty;

  ScanOutcome withResult(ScanResult next) =>
      ScanOutcome(end: end, result: next, error: error);
}

class ScanConfig {
  const ScanConfig({
    this.largeVideoBytes = 150 * 1000 * 1000,
    this.pageSize = 500,
    this.concurrency = 6,
    this.pdqMaxDistance = 31,
    this.pdqMinQuality = 10,
    this.pdqMaxBucketSize = 100000,
    this.hashFlushSize = 200,
    this.orbTopK = 10,
    this.orbMinInliers = 20,
  });

  /// Video từ ngưỡng này trở lên được coi là lớn.
  final int largeVideoBytes;
  final int pageSize;
  final int concurrency;

  /// Khoảng cách Hamming tối đa (trên 256 bit) của PDQ để coi là tương tự.
  /// Chưa hiệu chỉnh trên ảnh có nhãn; giá trị 31 lấy từ tài liệu PDQ.
  final int pdqMaxDistance;

  /// Ảnh có chất lượng PDQ thấp hơn mức này (gần như phẳng) không tham gia so
  /// sánh gần giống.
  final int pdqMinQuality;

  /// Bucket lớn hơn mức này bị bỏ qua để giữ chi phí có chặn trên.
  final int pdqMaxBucketSize;

  /// Số ảnh mới băm xong thì ghi xuống kho một lần.
  final int hashFlushSize;

  /// Số ảnh ứng viên mỗi ảnh được RANSAC kiểm tra (ORB).
  final int orbTopK;

  /// Số điểm khớp tối thiểu sau RANSAC để coi là cùng một ảnh gốc.
  final int orbMinInliers;
}

class CancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}
