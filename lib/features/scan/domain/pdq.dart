import 'dart:math' as math;
import 'dart:typed_data';

/// PDQ (Meta): hash 256 bit mô tả hình dạng tổng thể của ảnh.
///
/// Các bước: ảnh xám 64x64 -> DCT 2 chiều -> giữ khối 16x16 tần số thấp ->
/// so từng hệ số với trung vị (lớn hơn là 1). Khác bản gốc: chưa áp dụng bộ lọc
/// Jarosz trước khi thu nhỏ, vì ảnh đầu vào đã được codec thu về 64x64.
const int pdqSide = 64;
const int pdqBytes = 32;

/// Vân tay PDQ kèm điểm chất lượng (0..100). Ảnh gần như phẳng cho chất lượng
/// thấp và hash kém tin cậy.
class Pdq {
  const Pdq(this.bytes, this.quality);

  final Uint8List bytes;
  final int quality;

  /// Khoảng cách Hamming (0..256).
  int distanceTo(Pdq other) {
    var d = 0;
    for (var i = 0; i < pdqBytes; i++) {
      d += _popcount8[bytes[i] ^ other.bytes[i]];
    }
    return d;
  }
}

final List<int> _popcount8 = List.generate(256, (v) {
  var count = 0;
  for (var x = v; x > 0; x >>= 1) {
    count += x & 1;
  }
  return count;
});

/// Ma trận DCT-II: hàng u (0..15), cột x (0..63).
final List<List<double>> _dct = [
  for (var u = 0; u < 16; u++)
    [
      for (var x = 0; x < pdqSide; x++)
        (u == 0 ? math.sqrt(1 / pdqSide) : math.sqrt(2 / pdqSide)) *
            math.cos(math.pi * (2 * x + 1) * u / (2 * pdqSide)),
    ],
];

/// Tính PDQ từ ảnh xám 64x64 (4096 giá trị 0..255, theo hàng).
Pdq pdqFromLuma(List<int> luma) {
  if (luma.length != pdqSide * pdqSide) {
    throw ArgumentError('Cần ${pdqSide * pdqSide} giá trị, nhận ${luma.length}');
  }
  const n = pdqSide;

  // A[u][x] = sum_y C[u][y] * L[y][x], rồi F[u][v] = sum_x A[u][x] * C[v][x].
  final a = List.generate(16, (_) => List.filled(n, 0.0));
  for (var u = 0; u < 16; u++) {
    for (var y = 0; y < n; y++) {
      final c = _dct[u][y];
      for (var x = 0; x < n; x++) {
        a[u][x] += c * luma[y * n + x];
      }
    }
  }
  final coeffs = List<double>.filled(256, 0);
  for (var u = 0; u < 16; u++) {
    for (var v = 0; v < 16; v++) {
      var s = 0.0;
      for (var x = 0; x < n; x++) {
        s += a[u][x] * _dct[v][x];
      }
      coeffs[u * 16 + v] = s;
    }
  }

  final sorted = [...coeffs]..sort();
  final median = (sorted[127] + sorted[128]) / 2;
  final bytes = Uint8List(pdqBytes);
  for (var i = 0; i < 256; i++) {
    if (coeffs[i] > median) bytes[i ~/ 8] |= 1 << (7 - i % 8);
  }
  return Pdq(bytes, _quality(luma));
}

/// Độ chi tiết trung bình (chênh lệch điểm ảnh kề nhau), quy về 0..100.
/// Đây là ước lượng đơn giản, chưa phải công thức chính thức của PDQ.
int _quality(List<int> luma) {
  const n = pdqSide;
  var sum = 0;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final i = y * n + x;
      if (x + 1 < n) sum += (luma[i + 1] - luma[i]).abs();
      if (y + 1 < n) sum += (luma[i + n] - luma[i]).abs();
    }
  }
  final mean = sum / (2 * n * (n - 1));
  return math.min(100, (mean * 10).round());
}
