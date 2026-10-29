import 'package:cleanify/core/utils/format_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatShortDate thêm số 0 đầu', () {
    expect(formatShortDate(DateTime(2026, 3, 5)), '05/03/2026');
  });

  test('agoLabel theo phút, giờ, ngày', () {
    final now = DateTime(2026, 10, 29, 12);
    expect(agoLabel(now, now: now), 'Vừa xong');
    expect(agoLabel(now.subtract(const Duration(minutes: 8)), now: now), '8 phút');
    expect(agoLabel(now.subtract(const Duration(hours: 2)), now: now), '2 giờ');
    expect(agoLabel(now.subtract(const Duration(days: 3)), now: now), '3 ngày');
  });
}
