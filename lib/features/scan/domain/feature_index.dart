import 'dart:math' as math;
import 'dart:typed_data';

/// Đặc trưng ORB của một ảnh: mô tả nhị phân 256 bit (32 byte) và tọa độ điểm.
const int descriptorBytes = 32;

class FeatureSet {
  FeatureSet(this.descriptors, this.points)
      : count = descriptors.length ~/ descriptorBytes;

  /// count * 32 byte.
  final Uint8List descriptors;

  /// count * 2 giá trị (x, y).
  final Float32List points;
  final int count;

  static const _headerBytes = 4;

  /// Dạng nhị phân để lưu vào SQLite: [count int32][mô tả][tọa độ float32].
  Uint8List pack() {
    final out = ByteData(_headerBytes + descriptors.length + points.length * 4);
    out.setInt32(0, count, Endian.little);
    final bytes = out.buffer.asUint8List();
    bytes.setRange(
        _headerBytes, _headerBytes + descriptors.length, descriptors);
    final pointsAt = _headerBytes + descriptors.length;
    for (var i = 0; i < points.length; i++) {
      out.setFloat32(pointsAt + i * 4, points[i], Endian.little);
    }
    return bytes;
  }

  static FeatureSet? unpack(Uint8List bytes) {
    if (bytes.length < _headerBytes) return null;
    final data = ByteData.sublistView(bytes);
    final count = data.getInt32(0, Endian.little);
    final descLen = count * descriptorBytes;
    if (count < 0 || bytes.length != _headerBytes + descLen + count * 8) {
      return null;
    }
    final descriptors = Uint8List.fromList(
      bytes.sublist(_headerBytes, _headerBytes + descLen),
    );
    final points = Float32List(count * 2);
    final pointsAt = _headerBytes + descLen;
    for (var i = 0; i < points.length; i++) {
      points[i] = data.getFloat32(pointsAt + i * 4, Endian.little);
    }
    return FeatureSet(descriptors, points);
  }
}

/// Khớp hai bộ đặc trưng và trả về số điểm khớp theo cùng một phép biến đổi
/// (RANSAC). Đây là bước xác nhận, không phải bước tìm ứng viên.
abstract interface class FeatureMatcher {
  int inliers(FeatureSet a, FeatureSet b);
}

/// Chỉ mục LSH trên mô tả nhị phân để chọn ứng viên. Mỗi bảng dùng 16 bit cố
/// định của mô tả làm khóa; hai ảnh có nhiều mô tả giống nhau ở ít nhất một bảng
/// sẽ được đếm phiếu. Khóa 16 bit cho mảng bucket trực tiếp, không cần map.
class LshIndex {
  LshIndex._(this._offsets, this._owners, this._imageCount);

  static const int tables = 4;
  static const int _keyBits = 16;
  static const int _buckets = 1 << _keyBits;

  static final List<List<int>> _bitPositions = [
    for (var t = 0; t < tables; t++) _pickBits(t),
  ];

  final List<Int32List> _offsets; // mỗi bảng: _buckets + 1 phần tử
  final List<Int32List> _owners; // mỗi bảng: chỉ số ảnh theo bucket
  final int _imageCount;

  static List<int> _pickBits(int table) {
    final positions = List<int>.generate(descriptorBytes * 8, (i) => i);
    final rng = math.Random(table + 1);
    positions.shuffle(rng);
    return positions.sublist(0, _keyBits);
  }

  static int _key(Uint8List d, int at, List<int> bits) {
    var key = 0;
    for (final p in bits) {
      final byte = d[at + (p >> 3)];
      key = (key << 1) | ((byte >> (7 - (p & 7))) & 1);
    }
    return key;
  }

  /// Xây chỉ mục cho danh sách đặc trưng; chỉ số trong kết quả tìm kiếm là
  /// vị trí trong [sets].
  static LshIndex build(List<FeatureSet> sets) {
    final offsets = <Int32List>[];
    final owners = <Int32List>[];
    for (var t = 0; t < tables; t++) {
      final bits = _bitPositions[t];
      final counts = Int32List(_buckets + 1);
      final keyOf = <int>[];
      final ownerOf = <int>[];
      for (var img = 0; img < sets.length; img++) {
        final f = sets[img];
        for (var k = 0; k < f.count; k++) {
          final key = _key(f.descriptors, k * descriptorBytes, bits);
          keyOf.add(key);
          ownerOf.add(img);
          counts[key + 1]++;
        }
      }
      for (var b = 0; b < _buckets; b++) {
        counts[b + 1] += counts[b];
      }
      final fill = Int32List.fromList(counts);
      final list = Int32List(keyOf.length);
      for (var i = 0; i < keyOf.length; i++) {
        list[fill[keyOf[i]]++] = ownerOf[i];
      }
      offsets.add(counts);
      owners.add(list);
    }
    return LshIndex._(offsets, owners, sets.length);
  }

  /// Chọn tối đa [k] ảnh có nhiều phiếu nhất với [query], bỏ qua [self].
  List<int> nearest(FeatureSet query, {required int self, int k = 10}) {
    final votes = <int, int>{};
    for (var t = 0; t < tables; t++) {
      final bits = _bitPositions[t];
      final offsets = _offsets[t];
      final owners = _owners[t];
      for (var q = 0; q < query.count; q++) {
        final key = _key(query.descriptors, q * descriptorBytes, bits);
        for (var i = offsets[key]; i < offsets[key + 1]; i++) {
          final o = owners[i];
          if (o == self) continue;
          votes[o] = (votes[o] ?? 0) + 1;
        }
      }
    }
    final ranked = votes.keys.toList()
      ..sort((a, b) {
        final c = votes[b]!.compareTo(votes[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return ranked.take(k).toList();
  }

  int get imageCount => _imageCount;
}
