import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cleanify/features/scan/domain/feature_index.dart';
import 'package:flutter_test/flutter_test.dart';

FeatureSet randomFeatures(int seed, {int n = 120}) {
  final rng = math.Random(seed);
  final d = Uint8List.fromList(List.generate(n * descriptorBytes, (_) => rng.nextInt(256)));
  return FeatureSet(d, Float32List(n * 2));
}

/// Giữ một phần mô tả của [f], đổi phần còn lại: mô phỏng ảnh cắt.
FeatureSet partOf(FeatureSet f, {int keep = 80, int seed = 1}) {
  final rng = math.Random(seed);
  final d = Uint8List.fromList(f.descriptors.sublist(0, keep * descriptorBytes));
  return FeatureSet(d, Float32List(keep * 2));
}

void main() {
  test('gói và mở gói đặc trưng giữ nguyên dữ liệu', () {
    final f = randomFeatures(3);
    final back = FeatureSet.unpack(f.pack())!;
    expect(back.count, f.count);
    expect(back.descriptors, f.descriptors);
  });

  test('mở gói dữ liệu sai độ dài thì trả về null', () {
    expect(FeatureSet.unpack(Uint8List.fromList([1, 0, 0, 0, 9])), isNull);
  });

  test('ảnh có mô tả chung được chọn làm ứng viên đầu tiên', () {
    final sets = [
      for (var i = 0; i < 40; i++) randomFeatures(i),
    ];
    final index = LshIndex.build(sets);
    // Ảnh 17 bị cắt chỉ còn một phần mô tả.
    final query = partOf(sets[17]);

    final top = index.nearest(query, self: -1, k: 5);

    expect(top.first, 17);
  });

  test('không trả về chính ảnh truy vấn', () {
    final sets = [for (var i = 0; i < 10; i++) randomFeatures(i)];
    final index = LshIndex.build(sets);

    final top = index.nearest(sets[4], self: 4, k: 10);

    expect(top, isNot(contains(4)));
  });

  test('ảnh không có mô tả chung thì không có ứng viên', () {
    final sets = [for (var i = 0; i < 10; i++) randomFeatures(i)];
    final index = LshIndex.build(sets);

    final top = index.nearest(randomFeatures(999), self: -1, k: 10);

    expect(top.length, lessThan(10));
  });
}
