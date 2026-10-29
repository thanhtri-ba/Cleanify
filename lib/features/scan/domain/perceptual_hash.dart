import 'dart:math' as math;

import 'media_source.dart';

/// dHash 64 bit, tách thành hai nửa 32 bit để không phụ thuộc số nguyên 64 bit.
class ImageHash {
  const ImageHash(this.hi, this.lo);

  final int hi;
  final int lo;

  int distanceTo(ImageHash other) =>
      _popCount32(hi ^ other.hi) + _popCount32(lo ^ other.lo);

  /// Số bit 1 trong hash (0..64). Hash gần toàn 0 hoặc toàn 1 là ảnh ít chi
  /// tiết, kém tin cậy để so sánh.
  int get bitCount => _popCount32(hi) + _popCount32(lo);

  @override
  bool operator ==(Object other) =>
      other is ImageHash && other.hi == hi && other.lo == lo;

  @override
  int get hashCode => Object.hash(hi, lo);

  @override
  String toString() =>
      '${hi.toRadixString(16).padLeft(8, '0')}${lo.toRadixString(16).padLeft(8, '0')}';
}

int _popCount32(int value) {
  var v = value & 0xFFFFFFFF;
  v = v - ((v >> 1) & 0x55555555);
  v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
  v = (v + (v >> 4)) & 0x0F0F0F0F;
  return ((v * 0x01010101) & 0xFFFFFFFF) >> 24;
}

/// Mỗi hàng 9 điểm cho 8 phép so sánh (trái < phải) => đủ 64 bit.
ImageHash dHash(List<int> luma) {
  if (luma.length != lumaGridSize) {
    throw ArgumentError('Cần $lumaGridSize giá trị, nhận ${luma.length}');
  }
  var hi = 0;
  var lo = 0;
  var bit = 0;
  for (var row = 0; row < lumaGridHeight; row++) {
    for (var col = 0; col < lumaGridWidth - 1; col++) {
      final left = luma[row * lumaGridWidth + col];
      final right = luma[row * lumaGridWidth + col + 1];
      final isSet = left < right;
      if (bit < 32) {
        if (isSet) hi |= 1 << (31 - bit);
      } else {
        if (isSet) lo |= 1 << (63 - bit);
      }
      bit++;
    }
  }
  return ImageHash(hi, lo);
}

/// Hash của 8 hướng ảnh vuông: xoay 0/90/180/270 độ, và cùng bốn hướng sau
/// khi lật ngang. Ảnh xoay hoặc lật vẫn có một hướng khớp với ảnh gốc.
List<ImageHash> orientationHashes(List<int> square) {
  final n = math.sqrt(square.length).round();
  if (n * n != square.length || n < lumaGridWidth) {
    throw ArgumentError('Cần ảnh vuông, nhận ${square.length} giá trị');
  }
  return [
    for (var k = 0; k < 8; k++) dHash(_shrink(_orient(square, n, k), n)),
  ];
}

/// Khoảng cách nhỏ nhất giữa một ảnh (các hướng) và một hash khác.
int orientationDistance(List<ImageHash> variants, ImageHash other) {
  var best = 64;
  for (final v in variants) {
    final d = v.distanceTo(other);
    if (d < best) best = d;
  }
  return best;
}

/// Ảnh vuông n x n sau phép biến đổi thứ k: k % 4 lần xoay 90 độ, và lật
/// ngang nếu k >= 4.
List<int> _orient(List<int> src, int n, int k) {
  final out = List<int>.filled(n * n, 0);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      var sx = k >= 4 ? n - 1 - x : x;
      var sy = y;
      for (var r = 0; r < k % 4; r++) {
        final nx = n - 1 - sy;
        sy = sx;
        sx = nx;
      }
      out[y * n + x] = src[sy * n + sx];
    }
  }
  return out;
}

/// Thu ảnh vuông n x n xuống lưới 9x8 bằng trung bình từng ô.
List<int> _shrink(List<int> square, int n) {
  final out = List<int>.filled(lumaGridSize, 0);
  for (var row = 0; row < lumaGridHeight; row++) {
    final y0 = row * n ~/ lumaGridHeight;
    final y1 = (row + 1) * n ~/ lumaGridHeight;
    for (var col = 0; col < lumaGridWidth; col++) {
      final x0 = col * n ~/ lumaGridWidth;
      final x1 = (col + 1) * n ~/ lumaGridWidth;
      var sum = 0;
      var count = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          sum += square[y * n + x];
          count++;
        }
      }
      out[row * lumaGridWidth + col] = count == 0 ? 0 : sum ~/ count;
    }
  }
  return out;
}
