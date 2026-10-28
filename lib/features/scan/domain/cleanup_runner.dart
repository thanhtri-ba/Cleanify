import 'dart:math' as math;

import 'media_source.dart';
import 'scan_models.dart';

class CleanupProgress {
  const CleanupProgress({
    required this.processed,
    required this.total,
    required this.deleted,
  });

  final int processed;
  final int total;
  final int deleted;

  double get fraction => total == 0 ? 1 : processed / total;
}

class CleanupOutcome {
  const CleanupOutcome({
    required this.deletedIds,
    required this.remainingIds,
    this.cancelled = false,
    this.declined = false,
    this.error,
  });

  final List<String> deletedIds;
  final List<String> remainingIds;

  /// Người dùng bấm tạm dừng giữa các lượt.
  final bool cancelled;

  /// Người dùng từ chối hộp thoại xác nhận của hệ điều hành.
  final bool declined;
  final String? error;

  bool get isFullSuccess =>
      !cancelled && !declined && error == null && remainingIds.isEmpty;
}

/// Xóa theo từng lượt. Mỗi lượt là một lần gọi [MediaDeleter.delete] nên hệ
/// điều hành chỉ hỏi xác nhận một lần cho mỗi lượt (với đa số thư viện: 1 lần).
///
/// Dừng ngay khi: bị hủy, người dùng từ chối xác nhận, hoặc có lỗi, để không
/// hỏi lặp lại và không xóa thêm ngoài ý muốn.
class CleanupRunner {
  CleanupRunner(this.deleter, {this.chunkSize = 500});

  final MediaDeleter deleter;
  final int chunkSize;

  Future<CleanupOutcome> run(
    List<String> ids, {
    required CancelToken cancel,
    void Function(CleanupProgress progress)? onProgress,
  }) async {
    final unique = ids.toSet().toList();
    final deleted = <String>[];
    var processed = 0;
    var cancelled = false;
    var declined = false;
    String? error;

    for (var i = 0; i < unique.length; i += chunkSize) {
      if (cancel.isCancelled) {
        cancelled = true;
        break;
      }
      final chunk = unique.sublist(i, math.min(i + chunkSize, unique.length));
      try {
        final result = await deleter.delete(chunk);
        final inChunk = chunk.toSet();
        final confirmed = result.where(inChunk.contains).toList();
        deleted.addAll(confirmed);
        if (confirmed.isEmpty) {
          declined = true;
          break;
        }
      } catch (e) {
        error = e.toString();
        break;
      }
      processed += chunk.length;
      onProgress?.call(
        CleanupProgress(
          processed: processed,
          total: unique.length,
          deleted: deleted.length,
        ),
      );
    }

    final deletedSet = deleted.toSet();
    return CleanupOutcome(
      deletedIds: deleted,
      remainingIds: unique.where((id) => !deletedSet.contains(id)).toList(),
      cancelled: cancelled,
      declined: declined,
      error: error,
    );
  }
}
