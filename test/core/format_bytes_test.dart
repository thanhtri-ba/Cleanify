import 'package:cleanify/core/utils/format_bytes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('0 và số âm hiển thị 0 MB', () {
    expect(formatBytes(0), '0 MB');
    expect(formatBytes(-5), '0 MB');
  });

  test('dưới 1 MB hiển thị <1 MB', () {
    expect(formatBytes(400 * 1000), '<1 MB');
  });

  test('MB làm tròn số nguyên', () {
    expect(formatBytes(640 * 1000 * 1000 - 1), '640 MB');
    expect(formatBytes(230 * 1000 * 1000), '230 MB');
  });

  test('GB làm tròn một chữ số thập phân', () {
    expect(formatBytes(2400 * 1000 * 1000), '2.4 GB');
    expect(formatBytes(1000 * 1000 * 1000), '1.0 GB');
  });

  test('sát 1 GB không hiển thị 1000 MB', () {
    expect(formatBytes(999800 * 1000), '1.0 GB');
  });

  test('splitBytes tách số và đơn vị', () {
    final s = splitBytes(2400 * 1000 * 1000);
    expect(s.value, '2.4');
    expect(s.unit, 'GB');
  });

  test('formatCount thêm dấu phân cách hàng nghìn', () {
    expect(formatCount(0), '0');
    expect(formatCount(999), '999');
    expect(formatCount(1000), '1,000');
    expect(formatCount(12480), '12,480');
    expect(formatCount(1234567), '1,234,567');
  });
}
