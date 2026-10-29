import 'package:cleanify/features/scan/data/simulated_device_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gb = 1000 * 1000 * 1000;

  test('đã dùng = hệ thống + thư viện, còn trống = tổng trừ đã dùng', () async {
    final source = SimulatedDeviceStorageSource(
      libraryBytes: () async => 1 * gb,
      totalBytes: 58 * gb,
      systemBytes: 15 * gb,
    );

    final storage = await source.read();

    expect(storage.totalBytes, 58 * gb);
    expect(storage.usedBytes, 16 * gb);
    expect(storage.freeBytes, 42 * gb);
  });

  test('thêm ảnh thì đã dùng tăng', () async {
    var library = 0;
    final source = SimulatedDeviceStorageSource(
      libraryBytes: () async => library,
      totalBytes: 58 * gb,
      systemBytes: 15 * gb,
    );

    final before = await source.read();
    library = 900 * 1000 * 1000;
    final after = await source.read();

    expect(after.usedBytes - before.usedBytes, 900 * 1000 * 1000);
  });

  test('đã dùng vượt tổng thì còn trống bằng 0, không âm', () async {
    final source = SimulatedDeviceStorageSource(
      libraryBytes: () async => 100 * gb,
      totalBytes: 58 * gb,
      systemBytes: 15 * gb,
    );

    final storage = await source.read();

    expect(storage.freeBytes, 0);
  });
}
