import '../../scan/domain/scan_models.dart';

/// Một lần dọn dẹp đã hoàn tất, hiển thị ở tab Activity.
class CleanupSession {
  const CleanupSession({
    required this.id,
    required this.at,
    required this.bytes,
    required this.count,
    required this.categories,
    required this.completed,
  });

  final int id;
  final DateTime at;
  final int bytes;
  final int count;
  final List<ScanCategory> categories;

  /// Đã xóa hết mọi mục trong kế hoạch (không còn mục nào bị bỏ dở).
  final bool completed;

  Map<String, Object?> toJson() => {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'bytes': bytes,
        'count': count,
        'categories': [for (final c in categories) c.name],
        'completed': completed,
      };

  factory CleanupSession.fromJson(Map<String, Object?> json) => CleanupSession(
        id: json['id'] as int,
        at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
        bytes: json['bytes'] as int,
        count: json['count'] as int,
        categories: [
          for (final n in (json['categories'] as List<dynamic>? ?? const []))
            for (final c in ScanCategory.values)
              if (c.name == n) c,
        ],
        completed: json['completed'] as bool? ?? false,
      );
}
