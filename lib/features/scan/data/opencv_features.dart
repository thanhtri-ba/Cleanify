import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../domain/feature_index.dart';

/// Trích đặc trưng ORB và khớp bằng OpenCV. Tham số lấy từ bộ thử nghiệm trên
/// testset: 300 điểm, ngưỡng FAST 5, lọc Lowe 0.75, RANSAC 5 px.
class OpenCvFeatures {
  OpenCvFeatures._();

  static const int nFeatures = 300;
  static const int fastThreshold = 5;
  static const double loweRatio = 0.75;
  static const double ransacThreshold = 5.0;
  static const int minFeatures = 8;

  /// Đặc trưng từ ảnh mã hóa (JPEG/PNG). Null nếu ảnh quá ít chi tiết.
  static FeatureSet? extract(Uint8List encoded) {
    final img = cv.imdecode(encoded, cv.IMREAD_GRAYSCALE);
    if (img.isEmpty) {
      img.dispose();
      return null;
    }
    final orb = cv.ORB.create(
      nFeatures: nFeatures,
      fastThreshold: fastThreshold,
    );
    final (kps, des) = orb.detectAndCompute(img, cv.Mat.empty());
    try {
      final n = kps.length;
      if (n < minFeatures || des.rows != n) return null;
      final points = Float32List(n * 2);
      for (var i = 0; i < n; i++) {
        points[i * 2] = kps[i].x;
        points[i * 2 + 1] = kps[i].y;
      }
      final descriptors = Uint8List.fromList(des.data);
      return FeatureSet(descriptors, points);
    } finally {
      img.dispose();
      des.dispose();
      kps.dispose();
      orb.dispose();
    }
  }

  /// Số điểm khớp theo cùng một phép biến đổi (dịch, xoay, phóng to đều).
  static int inliers(FeatureSet a, FeatureSet b) {
    if (a.count < minFeatures || b.count < minFeatures) return 0;
    final da = cv.Mat.fromList(
      a.count,
      descriptorBytes,
      cv.MatType.CV_8UC1,
      a.descriptors,
    );
    final db = cv.Mat.fromList(
      b.count,
      descriptorBytes,
      cv.MatType.CV_8UC1,
      b.descriptors,
    );
    final bf = cv.BFMatcher.create(type: cv.NORM_HAMMING);
    final knn = bf.knnMatch(da, db, 2);
    final fromPts = <cv.Point2f>[];
    final toPts = <cv.Point2f>[];
    for (var i = 0; i < knn.length; i++) {
      final pair = knn[i];
      if (pair.length < 2) continue;
      final m = pair[0];
      final n = pair[1];
      if (m.distance < loweRatio * n.distance) {
        fromPts.add(
            cv.Point2f(a.points[m.queryIdx * 2], a.points[m.queryIdx * 2 + 1]));
        toPts.add(
            cv.Point2f(b.points[m.trainIdx * 2], b.points[m.trainIdx * 2 + 1]));
      }
    }
    final result =
        fromPts.length < minFeatures ? 0 : _ransacInliers(fromPts, toPts);
    bf.dispose();
    da.dispose();
    db.dispose();
    knn.dispose();
    return result;
  }

  static int _ransacInliers(List<cv.Point2f> from, List<cv.Point2f> to) {
    final src = cv.VecPoint2f.fromList(from);
    final dst = cv.VecPoint2f.fromList(to);
    final (model, mask) = cv.estimateAffinePartial2D(
      src,
      dst,
      ransacReprojThreshold: ransacThreshold,
    );
    var count = 0;
    if (!mask.isEmpty) {
      for (final v in mask.data) {
        if (v != 0) count++;
      }
    }
    model.dispose();
    mask.dispose();
    src.dispose();
    dst.dispose();
    return count;
  }
}

/// Cài đặt [FeatureMatcher] bằng OpenCV.
class OpenCvFeatureMatcher implements FeatureMatcher {
  const OpenCvFeatureMatcher();

  @override
  int inliers(FeatureSet a, FeatureSet b) => OpenCvFeatures.inliers(a, b);
}
