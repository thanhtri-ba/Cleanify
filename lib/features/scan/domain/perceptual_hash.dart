import 'media_source.dart';

/// dHash 64 bit, tách thành hai nửa 32 bit để không phụ thuộc số nguyên 64 bit.
class ImageHash {
  const ImageHash(this.hi, this.lo);

  final int hi;
  final int lo;

  int distanceTo(ImageHash other) =>
      _popCount32(hi ^ other.hi) + _popCount32(lo ^ other.lo);

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
