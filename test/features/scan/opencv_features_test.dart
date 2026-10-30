import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cleanify/features/scan/data/opencv_features.dart';
import 'package:cleanify/features/scan/domain/feature_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Ảnh có nhiều hình chữ nhật và đường nét ở vị trí ngẫu nhiên theo [seed].
Uint8List scene(int seed, {int size = 320}) {
  final rng = math.Random(seed);
  final img = cv.Mat.zeros(size, size, cv.MatType.CV_8UC3);
  for (var i = 0; i < 60; i++) {
    final x = rng.nextInt(size - 40), y = rng.nextInt(size - 40);
    final w = 8 + rng.nextInt(40), h = 8 + rng.nextInt(40);
    cv.rectangle(
      img,
      cv.Rect(x, y, w, h),
      cv.Scalar(rng.nextInt(256).toDouble(), rng.nextInt(256).toDouble(), rng.nextInt(256).toDouble()),
      thickness: -1,
    );
  }
  final (_, bytes) = cv.imencode('.png', img);
  img.dispose();
  return bytes;
}

Uint8List cropOf(Uint8List encoded) {
  final src = cv.imdecode(encoded, cv.IMREAD_COLOR);
  final part = src.region(cv.Rect(60, 40, 200, 220));
  final (_, out) = cv.imencode('.png', part);
  src.dispose();
  return out;
}

void main() {
  test('ảnh cắt của cùng một cảnh có nhiều điểm khớp hơn ảnh khác cảnh', () {
    final original = OpenCvFeatures.extract(scene(4));
    final cropped = OpenCvFeatures.extract(cropOf(scene(4)));
    final other = OpenCvFeatures.extract(scene(99));

    expect(original, isNotNull);
    expect(cropped, isNotNull);
    expect(other, isNotNull);
    final same = OpenCvFeatures.inliers(original!, cropped!);
    final diff = OpenCvFeatures.inliers(original, other!);
    expect(same, greaterThanOrEqualTo(15));
    expect(diff, lessThan(same));
  });

  test('ảnh phẳng không đủ điểm đặc trưng thì không trích được', () {
    final img = cv.Mat.zeros(200, 200, cv.MatType.CV_8UC1);
    final (_, bytes) = cv.imencode('.png', img);
    img.dispose();
    expect(OpenCvFeatures.extract(bytes), isNull);
  });

  test('gói và mở gói đặc trưng giữ nguyên dữ liệu', () {
    final f = OpenCvFeatures.extract(scene(7))!;
    final back = FeatureSet.unpack(f.pack())!;
    expect(back.count, f.count);
    expect(back.descriptors, f.descriptors);
    expect(back.points, f.points);
  });
}
