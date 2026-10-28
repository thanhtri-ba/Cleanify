import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cleanup_plan.dart';
import '../domain/media_scanner.dart';
import '../domain/scan_models.dart';
import 'scan_providers.dart';

enum ScanPhase { idle, running, finished }

class ScanState {
  const ScanState({
    this.phase = ScanPhase.idle,
    required this.progress,
    this.outcome,
  });

  factory ScanState.idle() => ScanState(progress: ScanProgress.initial());

  final ScanPhase phase;
  final ScanProgress progress;
  final ScanOutcome? outcome;

  ScanState copyWith({
    ScanPhase? phase,
    ScanProgress? progress,
    ScanOutcome? outcome,
  }) =>
      ScanState(
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        outcome: outcome ?? this.outcome,
      );
}

class ScanController extends Notifier<ScanState> {
  CancelToken? _token;
  int _runId = 0;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  ScanState build() => ScanState.idle();

  /// Bắt đầu lượt quét mới. Bỏ qua nếu đang quét (chống bấm đúp).
  Future<void> start() async {
    if (state.phase == ScanPhase.running) return;

    final token = CancelToken();
    _token = token;
    final runId = ++_runId;
    _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
    state = ScanState(
      phase: ScanPhase.running,
      progress: ScanProgress.initial(),
    );

    final scanner = MediaScanner(
      ref.read(mediaSourceProvider),
      config: ref.read(scanConfigProvider),
    );

    ScanOutcome outcome;
    try {
      outcome = await scanner.run(
        cancel: token,
        onProgress: (progress) {
          if (runId != _runId || state.phase != ScanPhase.running) return;
          // Giới hạn tần suất cập nhật để không dựng lại UI quá dày.
          final now = DateTime.now();
          if (now.difference(_lastEmit) < const Duration(milliseconds: 80)) {
            return;
          }
          _lastEmit = now;
          state = state.copyWith(progress: progress);
        },
      );
    } catch (e) {
      outcome = ScanOutcome(
        end: ScanEnd.interrupted,
        result: const ScanResult(),
        error: e.toString(),
      );
    }

    if (runId != _runId) return;
    state = ScanState(
      phase: ScanPhase.finished,
      progress: state.progress,
      outcome: outcome,
    );
    ref.read(cleanupPlanProvider.notifier).reset(outcome.result);
  }

  /// Dừng quét (người dùng bấm Stop Scan).
  void cancel() => _token?.cancel();

  /// Gỡ các mục đã xóa khỏi kết quả quét để Home và các màn khác cập nhật.
  void removeDeleted(Set<String> ids) {
    final outcome = state.outcome;
    if (outcome == null || ids.isEmpty) return;
    final next = outcome.withResult(outcome.result.without(ids));
    state = state.copyWith(outcome: next);
    ref.read(cleanupPlanProvider.notifier).reset(next.result);
  }
}

final scanControllerProvider =
    NotifierProvider<ScanController, ScanState>(ScanController.new);

/// Kế hoạch xóa hiện tại (mục người dùng đã chọn). null khi chưa có kết quả.
class CleanupPlanNotifier extends Notifier<CleanupPlan?> {
  @override
  CleanupPlan? build() => null;

  void reset(ScanResult result) => state = CleanupPlan.all(result);

  void toggleCategory(ScanCategory category) {
    final plan = state;
    if (plan != null) state = plan.toggleCategory(category);
  }

  void toggleItem(String id) {
    final plan = state;
    if (plan != null) state = plan.toggleItem(id);
  }
}

final cleanupPlanProvider =
    NotifierProvider<CleanupPlanNotifier, CleanupPlan?>(CleanupPlanNotifier.new);
