import 'package:cleanify/features/scan/domain/cleanup_runner.dart';
import 'package:cleanify/features/scan/domain/media_source.dart';
import 'package:cleanify/features/scan/domain/scan_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Deleter implements MediaDeleter {
  _Deleter({this.confirm = true, this.failOnCall, this.onCall});

  final bool confirm;
  final int? failOnCall;
  final void Function(int call)? onCall;
  final List<List<String>> calls = [];

  @override
  Future<List<String>> delete(List<String> ids) async {
    calls.add(ids);
    onCall?.call(calls.length);
    if (failOnCall == calls.length) throw StateError('boom');
    return confirm ? ids : const [];
  }
}

List<String> ids(int n) => [for (var i = 0; i < n; i++) 'id$i'];

void main() {
  test('xóa theo từng lượt và báo tiến độ', () async {
    final deleter = _Deleter();
    final progress = <CleanupProgress>[];

    final outcome = await CleanupRunner(deleter, chunkSize: 2).run(
      ids(5),
      cancel: CancelToken(),
      onProgress: progress.add,
    );

    expect(deleter.calls.map((c) => c.length), [2, 2, 1]);
    expect(outcome.deletedIds, ids(5));
    expect(outcome.remainingIds, isEmpty);
    expect(outcome.isFullSuccess, isTrue);
    expect(progress.map((p) => p.fraction), [0.4, 0.8, 1.0]);
  });

  test('loại id trùng nhau', () async {
    final deleter = _Deleter();
    final outcome = await CleanupRunner(deleter)
        .run(['a', 'b', 'a'], cancel: CancelToken());
    expect(outcome.deletedIds, ['a', 'b']);
  });

  test('người dùng từ chối xác nhận: dừng ngay, không hỏi lại', () async {
    final deleter = _Deleter(confirm: false);

    final outcome = await CleanupRunner(deleter, chunkSize: 2)
        .run(ids(6), cancel: CancelToken());

    expect(deleter.calls, hasLength(1));
    expect(outcome.declined, isTrue);
    expect(outcome.deletedIds, isEmpty);
    expect(outcome.remainingIds, ids(6));
    expect(outcome.isFullSuccess, isFalse);
  });

  test('tạm dừng giữa các lượt: các lượt sau không chạy', () async {
    final cancel = CancelToken();
    final deleter = _Deleter(onCall: (call) {
      if (call == 1) cancel.cancel();
    });

    final outcome =
        await CleanupRunner(deleter, chunkSize: 2).run(ids(6), cancel: cancel);

    expect(deleter.calls, hasLength(1));
    expect(outcome.cancelled, isTrue);
    expect(outcome.deletedIds, ['id0', 'id1']);
    expect(outcome.remainingIds, ['id2', 'id3', 'id4', 'id5']);
  });

  test('lỗi ở lượt 2: giữ kết quả lượt 1 và báo lỗi', () async {
    final deleter = _Deleter(failOnCall: 2);

    final outcome = await CleanupRunner(deleter, chunkSize: 2)
        .run(ids(6), cancel: CancelToken());

    expect(outcome.error, contains('boom'));
    expect(outcome.deletedIds, ['id0', 'id1']);
    expect(outcome.remainingIds, hasLength(4));
  });

  test('deleter trả về id ngoài lượt thì bị bỏ qua', () async {
    final outcome =
        await CleanupRunner(_Wild()).run(['a'], cancel: CancelToken());
    expect(outcome.deletedIds, ['a']);
  });

  test('danh sách rỗng: không gọi deleter', () async {
    final deleter = _Deleter();
    final outcome = await CleanupRunner(deleter).run([], cancel: CancelToken());
    expect(deleter.calls, isEmpty);
    expect(outcome.isFullSuccess, isTrue);
  });
}

class _Wild implements MediaDeleter {
  @override
  Future<List<String>> delete(List<String> ids) async => [...ids, 'zzz'];
}
