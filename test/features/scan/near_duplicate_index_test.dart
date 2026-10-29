import 'dart:math' as math;

import 'package:cleanify/features/scan/domain/near_duplicate_index.dart';
import 'package:cleanify/features/scan/domain/perceptual_hash.dart';
import 'package:flutter_test/flutter_test.dart';

ImageHash flipBits(ImageHash base, List<int> positions) {
  var hi = base.hi;
  var lo = base.lo;
  for (final p in positions) {
    if (p < 32) {
      hi ^= 1 << (31 - p);
    } else {
      lo ^= 1 << (63 - p);
    }
  }
  return ImageHash(hi, lo);
}

Set<String> bruteForce(List<ImageHash> hashes, int maxDistance) {
  final out = <String>{};
  for (var i = 0; i < hashes.length; i++) {
    for (var j = i + 1; j < hashes.length; j++) {
      if (hashes[i].distanceTo(hashes[j]) <= maxDistance) out.add('$i-$j');
    }
  }
  return out;
}

Set<String> keys(List<(int, int)> pairs) =>
    {for (final (a, b) in pairs) '$a-$b'};

void main() {
  test('bitCount đếm đúng số bit 1', () {
    expect(const ImageHash(0, 0).bitCount, 0);
    expect(const ImageHash(0xFFFFFFFF, 0xFFFFFFFF).bitCount, 64);
    expect(const ImageHash(0x0000000F, 0x80000000).bitCount, 5);
  });

  test('khớp với so sánh vét cạn ở mọi khoảng cách 0..3', () async {
    final random = math.Random(42);
    final hashes = <ImageHash>[];
    // 150 hash ngẫu nhiên, mỗi hash kèm 0..3 bản sao lệch 0..3 bit.
    for (var i = 0; i < 150; i++) {
      final base = ImageHash(random.nextInt(1 << 32), random.nextInt(1 << 32));
      hashes.add(base);
      final copies = random.nextInt(4);
      for (var c = 0; c < copies; c++) {
        final flips = random.nextInt(4);
        final positions = <int>{};
        while (positions.length < flips) {
          positions.add(random.nextInt(64));
        }
        hashes.add(flipBits(base, positions.toList()));
      }
    }

    for (final distance in [0, 1, 2, 3]) {
      final found = await findNearDuplicatePairs(hashes, maxDistance: distance);
      final expected = bruteForce(hashes, distance);
      expect(keys(found), expected, reason: 'khoảng cách $distance');
      expect(found.length, expected.length, reason: 'không có cặp lặp');
    }
  });

  test('cặp khác 4 bit không được báo khi giới hạn là 3', () async {
    final base = ImageHash(0x12345678, 0x9ABCDEF0);
    final hashes = [base, flipBits(base, [0, 1, 2, 3])];
    expect(await findNearDuplicatePairs(hashes, maxDistance: 3), isEmpty);
  });

  test('maxDistance lớn hơn 3 bị giới hạn về 3', () async {
    final base = ImageHash(0x12345678, 0x9ABCDEF0);
    final hashes = [base, flipBits(base, [0, 20, 40, 60])];
    expect(await findNearDuplicatePairs(hashes, maxDistance: 10), isEmpty);
  });

  test('xô quá lớn bị bỏ qua để chặn chi phí', () async {
    const same = ImageHash(0x0F0F0F0F, 0xF0F0F0F0);
    final hashes = List<ImageHash>.filled(10, same);
    expect(
      await findNearDuplicatePairs(hashes, maxDistance: 0, maxBucketSize: 5),
      isEmpty,
    );
    final all = await findNearDuplicatePairs(hashes, maxDistance: 0);
    expect(all.length, 45);
  });

  test('check được gọi và có thể ngắt giữa chừng', () async {
    const same = ImageHash(0x0F0F0F0F, 0xF0F0F0F0);
    var calls = 0;
    await expectLater(
      () => findNearDuplicatePairs(
        [same, same],
        maxDistance: 0,
        check: () {
          calls++;
          throw StateError('cancelled');
        },
      ),
      throwsStateError,
    );
    expect(calls, 1);
  });

  test('danh sách rỗng hoặc một phần tử không có cặp', () async {
    expect(await findNearDuplicatePairs(const [], maxDistance: 3), isEmpty);
    expect(
      await findNearDuplicatePairs(const [ImageHash(1, 2)], maxDistance: 3),
      isEmpty,
    );
  });
}
