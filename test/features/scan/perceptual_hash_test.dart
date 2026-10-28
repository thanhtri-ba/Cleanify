import 'package:cleanify/features/scan/domain/perceptual_hash.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

void main() {
  test('cùng một ảnh cho cùng hash, khoảng cách 0', () {
    final a = dHash(lumaForBits(bitsOf(2)));
    final b = dHash(lumaForBits(bitsOf(2)));
    expect(a, b);
    expect(a.distanceTo(b), 0);
  });

  test('khoảng cách Hamming bằng số bit khác nhau', () {
    final base = dHash(lumaForBits(bitsOf(2)));
    for (final flips in [1, 5, 32, 40, 64]) {
      final other = dHash(lumaForBits(bitsOf(2, flip: flips)));
      expect(base.distanceTo(other), flips, reason: '$flips bit');
    }
  });

  test('toàn 0 và toàn 1 khác nhau 64 bit', () {
    final zeros = dHash(lumaForBits(bitsOf(0)));
    final ones = dHash(lumaForBits(bitsOf(1)));
    expect(zeros.distanceTo(ones), 64);
    expect(zeros.hi, 0);
    expect(zeros.lo, 0);
    expect(ones.hi, 0xFFFFFFFF);
    expect(ones.lo, 0xFFFFFFFF);
  });

  test('ảnh phẳng (mọi điểm bằng nhau) cho hash toàn 0', () {
    final flat = dHash(List<int>.filled(72, 100));
    expect(flat.hi, 0);
    expect(flat.lo, 0);
  });

  test('đầu vào sai kích thước bị từ chối', () {
    expect(() => dHash(const [1, 2, 3]), throwsArgumentError);
  });
}
