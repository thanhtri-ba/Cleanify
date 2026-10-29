import 'package:cleanify/features/scan/domain/media_source.dart';
import 'package:cleanify/features/scan/domain/perceptual_hash.dart';
import 'package:flutter_test/flutter_test.dart';

const n = lumaSquareSize;

/// Ảnh vuông có nhiều vùng sáng tối khác nhau, không đối xứng.
List<int> scene(int seed) {
  var s = seed;
  int next() {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s;
  }

  final blobs = [
    for (var i = 0; i < 12; i++)
      (next() % n, next() % n, 4 + next() % 10, next() % 256),
  ];
  return [
    for (var y = 0; y < n; y++)
      for (var x = 0; x < n; x++)
        () {
          var v = (x * 255 ~/ (n - 1) + y * 60 ~/ (n - 1)) ~/ 2;
          for (final (cx, cy, r, level) in blobs) {
            final dx = x - cx, dy = y - cy;
            if (dx * dx + dy * dy <= r * r) v = (v + level) ~/ 2;
          }
          return v;
        }(),
  ];
}

List<int> rotate90(List<int> src) => [
      for (var y = 0; y < n; y++)
        for (var x = 0; x < n; x++) src[(n - 1 - x) * n + y],
    ];

List<int> flipH(List<int> src) => [
      for (var y = 0; y < n; y++)
        for (var x = 0; x < n; x++) src[y * n + (n - 1 - x)],
    ];

int distanceToScene(List<int> a, List<int> b) =>
    orientationDistance(orientationHashes(a), orientationHashes(b).first);

void main() {
  test('ảnh xoay 90, 180, 270 độ vẫn khớp ảnh gốc', () {
    final original = scene(7);
    final r1 = rotate90(original);
    final r2 = rotate90(r1);
    final r3 = rotate90(r2);

    for (final rotated in [r1, r2, r3]) {
      expect(distanceToScene(original, rotated), lessThanOrEqualTo(6));
    }
  });

  test('ảnh lật ngang vẫn khớp ảnh gốc', () {
    final original = scene(7);

    expect(distanceToScene(original, flipH(original)), lessThanOrEqualTo(6));
  });

  test('ảnh khác nội dung không khớp dù có xoay', () {
    final original = scene(7);
    final other = scene(99);

    expect(distanceToScene(original, rotate90(other)),
        greaterThan(6));
  });

  test('ảnh vuông sai kích thước bị từ chối', () {
    expect(() => orientationHashes(List.filled(50, 0)), throwsArgumentError);
  });
}
