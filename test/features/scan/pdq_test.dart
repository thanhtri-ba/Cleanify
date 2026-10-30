import 'package:cleanify/features/scan/domain/pdq.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

void main() {
  test('hash có đúng 32 byte (256 bit)', () {
    expect(pdqFromLuma(patternLuma(1)).bytes, hasLength(pdqBytes));
  });

  test('cùng ảnh cho cùng hash, khoảng cách 0', () {
    final a = pdqFromLuma(patternLuma(4));
    final b = pdqFromLuma(patternLuma(4));
    expect(a.distanceTo(b), 0);
  });

  test('sáng hơn một chút vẫn gần nhau; cảnh khác thì xa', () {
    final base = pdqFromLuma(patternLuma(3));
    final brighter = pdqFromLuma([
      for (final v in patternLuma(3)) (v + 4).clamp(0, 255),
    ]);
    final other = pdqFromLuma(patternLuma(8));

    expect(base.distanceTo(brighter), lessThanOrEqualTo(31));
    expect(base.distanceTo(other), greaterThan(31));
  });

  test('ảnh phẳng có chất lượng 0, ảnh có chi tiết có chất lượng cao', () {
    expect(pdqFromLuma(flatLuma(128)).quality, 0);
    expect(pdqFromLuma(patternLuma(2)).quality, greaterThan(30));
  });

  test('sai kích thước đầu vào bị từ chối', () {
    expect(() => pdqFromLuma(List.filled(10, 0)), throwsArgumentError);
  });
}
