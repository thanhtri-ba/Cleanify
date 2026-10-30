import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

void main() {
  test('OpenCV ORB phát hiện đặc trưng trên ảnh có chi tiết', () {
    final img = cv.Mat.zeros(200, 200, cv.MatType.CV_8UC1);
    cv.rectangle(img, cv.Rect(20, 20, 60, 60), cv.Scalar(255, 255, 255));
    cv.rectangle(img, cv.Rect(120, 90, 50, 70), cv.Scalar(200, 200, 200));
    final orb = cv.ORB.create(nFeatures: 300);
    final (kps, des) = orb.detectAndCompute(img, cv.Mat.empty());
    expect(kps.length, greaterThan(0));
    expect(des.rows, kps.length);
    img.dispose();
    des.dispose();
  });
}
