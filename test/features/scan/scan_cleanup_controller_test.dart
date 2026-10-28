import 'package:cleanify/features/scan/application/cleanup_controller.dart';
import 'package:cleanify/features/scan/application/scan_controller.dart';
import 'package:cleanify/features/scan/application/scan_providers.dart';
import 'package:cleanify/features/scan/domain/media_source.dart';
import 'package:cleanify/features/scan/domain/scan_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

class _Deleter implements MediaDeleter {
  _Deleter({this.confirm = true});

  final bool confirm;
  final List<List<String>> calls = [];

  @override
  Future<List<String>> delete(List<String> ids) async {
    calls.add(ids);
    return confirm ? ids : const [];
  }
}

ProviderContainer makeContainer(_Deleter deleter) {
  final source = FakeMediaSource(
    [
      photo('a'),
      photo('b', screenshot: true),
      photo('c', screenshot: true),
    ],
    sizes: {'a': 1000000, 'b': 5000000, 'c': 5000000},
  );
  final container = ProviderContainer(
    overrides: [
      mediaSourceProvider.overrideWithValue(source),
      mediaDeleterProvider.overrideWithValue(deleter),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('quét xong: có kết quả và kế hoạch xóa chọn sẵn các mục', () async {
    final container = makeContainer(_Deleter());

    await container.read(scanControllerProvider.notifier).start();

    final scan = container.read(scanControllerProvider);
    expect(scan.phase, ScanPhase.finished);
    expect(scan.outcome!.end, ScanEnd.completed);
    expect(scan.outcome!.result.screenshots.map((i) => i.id), ['b', 'c']);

    final plan = container.read(cleanupPlanProvider)!;
    expect(plan.bytes, 10000000);
    expect(plan.isEmpty, isFalse);
  });

  test('xóa thành công: gỡ mục đã xóa khỏi kết quả và kế hoạch', () async {
    final deleter = _Deleter();
    final container = makeContainer(deleter);
    await container.read(scanControllerProvider.notifier).start();

    await container.read(cleanupControllerProvider.notifier).start();

    final cleanup = container.read(cleanupControllerProvider);
    expect(cleanup.phase, CleanupPhase.finished);
    expect(cleanup.outcome!.isFullSuccess, isTrue);
    expect(cleanup.deletedBytes, 10000000);
    expect(cleanup.deletedByCategory[ScanCategory.screenshots], 10000000);
    expect(deleter.calls.single.toSet(), {'b', 'c'});

    final result = container.read(scanControllerProvider).outcome!.result;
    expect(result.screenshots, isEmpty);
    expect(container.read(cleanupPlanProvider)!.isEmpty, isTrue);
  });

  test('người dùng từ chối xác nhận: không gỡ gì khỏi kết quả', () async {
    final container = makeContainer(_Deleter(confirm: false));
    await container.read(scanControllerProvider.notifier).start();

    await container.read(cleanupControllerProvider.notifier).start();

    final cleanup = container.read(cleanupControllerProvider);
    expect(cleanup.outcome!.declined, isTrue);
    expect(cleanup.outcome!.isFullSuccess, isFalse);
    expect(cleanup.deletedBytes, 0);
    expect(
      container.read(scanControllerProvider).outcome!.result.screenshots,
      hasLength(2),
    );
    expect(container.read(cleanupPlanProvider)!.bytes, 10000000);
  });

  test('không có kế hoạch xóa thì start() không làm gì', () async {
    final deleter = _Deleter();
    final container = makeContainer(deleter);

    await container.read(cleanupControllerProvider.notifier).start();

    expect(container.read(cleanupControllerProvider).phase, CleanupPhase.idle);
    expect(deleter.calls, isEmpty);
  });
}
