import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/application/cleanup_history.dart';
import '../../activity/domain/cleanup_session.dart';
import '../domain/cleanup_runner.dart';
import '../domain/scan_models.dart';
import 'scan_controller.dart';
import 'scan_providers.dart';

enum CleanupPhase { idle, running, finished }

/// Kết quả lần dọn gần nhất (chỉ trong phiên hiện tại), dùng cho thông báo.
class LastCleanup {
  const LastCleanup({
    required this.bytes,
    required this.count,
    required this.at,
    required this.byCategory,
  });

  final int bytes;
  final int count;
  final DateTime at;
  final Map<ScanCategory, int> byCategory;
}

class LastCleanupNotifier extends Notifier<LastCleanup?> {
  @override
  LastCleanup? build() => null;

  void record(LastCleanup value) => state = value;
}

final lastCleanupProvider = NotifierProvider<LastCleanupNotifier, LastCleanup?>(
    LastCleanupNotifier.new);

class CleanupState {
  const CleanupState({
    this.phase = CleanupPhase.idle,
    this.fraction = 0,
    this.selectedCount = 0,
    this.totalBytes = 0,
    this.processedBytes = 0,
    this.pausing = false,
    this.outcome,
    this.deletedBytes = 0,
    this.deletedByCategory = const {},
  });

  final CleanupPhase phase;
  final double fraction;
  final int selectedCount;
  final int totalBytes;
  final int processedBytes;

  /// Đã bấm tạm dừng, đang chờ lượt hiện tại xong.
  final bool pausing;
  final CleanupOutcome? outcome;
  final int deletedBytes;
  final Map<ScanCategory, int> deletedByCategory;

  int get remainingBytes => (totalBytes - processedBytes).clamp(0, totalBytes);
  int get percent => (fraction * 100).floor();

  CleanupState copyWith({
    CleanupPhase? phase,
    double? fraction,
    int? processedBytes,
    bool? pausing,
    CleanupOutcome? outcome,
    int? deletedBytes,
    Map<ScanCategory, int>? deletedByCategory,
  }) =>
      CleanupState(
        phase: phase ?? this.phase,
        fraction: fraction ?? this.fraction,
        selectedCount: selectedCount,
        totalBytes: totalBytes,
        processedBytes: processedBytes ?? this.processedBytes,
        pausing: pausing ?? this.pausing,
        outcome: outcome ?? this.outcome,
        deletedBytes: deletedBytes ?? this.deletedBytes,
        deletedByCategory: deletedByCategory ?? this.deletedByCategory,
      );
}

class CleanupController extends Notifier<CleanupState> {
  CancelToken? _token;

  @override
  CleanupState build() => const CleanupState();

  /// Xóa các mục đang chọn. Bỏ qua nếu đang chạy hoặc không có gì để xóa.
  Future<void> start() async {
    if (state.phase == CleanupPhase.running) return;
    final plan = ref.read(cleanupPlanProvider);
    if (plan == null || plan.isEmpty) return;

    final ids = plan.orderedIds;
    final sizes = [for (final id in ids) plan.bytesOfId(id)];
    final token = CancelToken();
    _token = token;

    state = CleanupState(
      phase: CleanupPhase.running,
      selectedCount: ids.length,
      totalBytes: plan.bytes,
    );

    final runner = CleanupRunner(ref.read(mediaDeleterProvider));
    CleanupOutcome outcome;
    try {
      outcome = await runner.run(
        ids,
        cancel: token,
        onProgress: (p) {
          var bytes = 0;
          for (var i = 0; i < p.processed && i < sizes.length; i++) {
            bytes += sizes[i];
          }
          state = state.copyWith(fraction: p.fraction, processedBytes: bytes);
        },
      );
    } catch (e) {
      outcome = CleanupOutcome(
        deletedIds: const [],
        remainingIds: ids,
        error: e.toString(),
      );
    }

    final deleted = outcome.deletedIds.toSet();
    final byCategory = {
      for (final c in ScanCategory.values)
        if (plan.bytesFor(c, only: deleted) > 0 || plan.countFor(c) > 0)
          c: plan.bytesFor(c, only: deleted),
    };
    state = state.copyWith(
      phase: CleanupPhase.finished,
      fraction: outcome.isFullSuccess ? 1 : state.fraction,
      outcome: outcome,
      deletedBytes: plan.bytesFor(ScanCategory.duplicates, only: deleted) +
          plan.bytesFor(ScanCategory.similar, only: deleted) +
          plan.bytesFor(ScanCategory.largeVideos, only: deleted) +
          plan.bytesFor(ScanCategory.screenshots, only: deleted),
      deletedByCategory: byCategory,
    );

    if (deleted.isNotEmpty) {
      ref.read(lastCleanupProvider.notifier).record(LastCleanup(
            bytes: state.deletedBytes,
            count: deleted.length,
            at: DateTime.now(),
            byCategory: byCategory,
          ));
      ref.read(cleanupHistoryProvider.notifier).add(CleanupSession(
            id: DateTime.now().microsecondsSinceEpoch,
            at: DateTime.now(),
            bytes: state.deletedBytes,
            count: deleted.length,
            categories: [
              for (final c in ScanCategory.values)
                if ((byCategory[c] ?? 0) > 0) c,
            ],
            completed: outcome.isFullSuccess,
          ));
      ref.read(scanControllerProvider.notifier).removeDeleted(deleted);
    }
  }

  /// Dừng sau lượt hiện tại. Phần đã xóa được giữ nguyên.
  void pause() {
    if (state.phase != CleanupPhase.running) return;
    _token?.cancel();
    state = state.copyWith(pausing: true);
  }

  void reset() => state = const CleanupState();
}

final cleanupControllerProvider =
    NotifierProvider<CleanupController, CleanupState>(CleanupController.new);
