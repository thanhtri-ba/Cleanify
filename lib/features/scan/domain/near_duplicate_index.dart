import 'dart:math' as math;

import 'perceptual_hash.dart';

/// Số đoạn chia hash 64 bit (mỗi đoạn 16 bit).
const int _chunkCount = 4;

/// Khoảng cách Hamming lớn nhất mà chỉ mục đảm bảo tìm đủ.
///
/// Chia hash thành 4 đoạn. Nếu hai hash khác nhau tối đa 3 bit thì có nhiều
/// nhất 3 đoạn bị ảnh hưởng, nên ít nhất 1 đoạn giống hệt (nguyên lý chuồng
/// bồ câu). Chỉ cần so các hash trùng nhau ở một đoạn nào đó, không phải so
/// mọi cặp.
const int maxIndexedDistance = _chunkCount - 1;

int _chunkOf(ImageHash hash, int chunk) {
  switch (chunk) {
    case 0:
      return (hash.hi >> 16) & 0xFFFF;
    case 1:
      return hash.hi & 0xFFFF;
    case 2:
      return (hash.lo >> 16) & 0xFFFF;
    default:
      return hash.lo & 0xFFFF;
  }
}

/// Tìm mọi cặp chỉ số (i, j), i < j, có khoảng cách Hamming <= [maxDistance].
///
/// [maxDistance] bị giới hạn trong 0..[maxIndexedDistance].
///
/// Xô có hơn [maxBucketSize] hash bị bỏ qua để tránh bùng nổ chi phí (thường
/// là các ảnh gần như phẳng cho cùng một đoạn hash). Kết quả khi đó có thể
/// thiếu một số cặp; người gọi nên loại ảnh ít thông tin trước.
///
/// [check] được gọi định kỳ để người gọi ném lỗi hủy; hàm cũng nhường vòng
/// lặp sự kiện định kỳ để không làm đơ giao diện.
Future<List<(int, int)>> findNearDuplicatePairs(
  List<ImageHash> hashes, {
  required int maxDistance,
  int maxBucketSize = 300,
  void Function()? check,
}) async {
  final limit = math.min(maxIndexedDistance, math.max(0, maxDistance));
  final n = hashes.length;
  final seen = <int>{};
  final pairs = <(int, int)>[];

  for (var chunk = 0; chunk < _chunkCount; chunk++) {
    check?.call();
    final buckets = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      buckets.putIfAbsent(_chunkOf(hashes[i], chunk), () => []).add(i);
    }

    var work = 0;
    for (final bucket in buckets.values) {
      if (bucket.length < 2 || bucket.length > maxBucketSize) continue;
      for (var a = 0; a < bucket.length; a++) {
        for (var b = a + 1; b < bucket.length; b++) {
          // Chỉ số trong xô tăng dần nên bucket[a] < bucket[b].
          final i = bucket[a];
          final j = bucket[b];
          if (hashes[i].distanceTo(hashes[j]) > limit) continue;
          if (seen.add(i * n + j)) pairs.add((i, j));
        }
      }
      work += bucket.length * bucket.length;
      if (work >= 20000) {
        work = 0;
        check?.call();
        await Future<void>.delayed(Duration.zero);
      }
    }
  }
  return pairs;
}
