import 'package:cleanify/core/router/app_routes.dart';
import 'package:cleanify/features/scan/application/scan_routing.dart';
import 'package:cleanify/features/scan/domain/scan_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

void main() {
  final withItems = ScanResult(
    screenshots: [photo('s', screenshot: true).withSize(1000)],
    completed: ScanCategory.values.toSet(),
  );
  final emptyAll = ScanResult(completed: ScanCategory.values.toSet());

  test('hoàn tất có kết quả -> Scan Complete', () {
    expect(
      routeForOutcome(ScanOutcome(end: ScanEnd.completed, result: withItems)),
      AppRoutes.scanComplete,
    );
  });

  test('hoàn tất không có gì -> No Items', () {
    expect(
      routeForOutcome(ScanOutcome(end: ScanEnd.completed, result: emptyAll)),
      AppRoutes.scanEmpty,
    );
  });

  test('gián đoạn nhưng có danh mục xong -> Partial', () {
    expect(
      routeForOutcome(
        const ScanOutcome(
          end: ScanEnd.interrupted,
          result: ScanResult(completed: {ScanCategory.screenshots}),
        ),
      ),
      AppRoutes.scanPartial,
    );
  });

  test('gián đoạn khi chưa xong danh mục nào -> Error', () {
    expect(
      routeForOutcome(
        const ScanOutcome(end: ScanEnd.interrupted, result: ScanResult()),
      ),
      AppRoutes.scanError,
    );
  });

  test('người dùng dừng -> quay lại (null)', () {
    expect(
      routeForOutcome(
        const ScanOutcome(end: ScanEnd.cancelled, result: ScanResult()),
      ),
      isNull,
    );
  });
}
