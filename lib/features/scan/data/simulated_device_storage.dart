import 'dart:math' as math;

import '../domain/device_storage.dart';

/// Giả lập dung lượng iPhone trên simulator (chỉ bật khi chạy với
/// `--dart-define=SIMULATED_STORAGE=true`). Ổ của simulator là ổ Mac, nên
/// không phản ánh đúng máy thật.
///
/// Đã dùng = dung lượng nền hệ thống + tổng file gốc của thư viện, nên khi
/// thêm ảnh/video con số sẽ tăng như trên máy thật.
class SimulatedDeviceStorageSource implements DeviceStorageSource {
  const SimulatedDeviceStorageSource({
    required this.libraryBytes,
    this.totalBytes = iPhone11_64GbUsableBytes,
    this.systemBytes = defaultSystemBytes,
  });

  /// iPhone 11 64 GB: Cài đặt báo khoảng 58.9 GB dùng được.
  static const int iPhone11_64GbUsableBytes = 58900000000;
  static const int defaultSystemBytes = 15000000000;

  final Future<int> Function() libraryBytes;
  final int totalBytes;
  final int systemBytes;

  @override
  Future<DeviceStorage> read() async {
    final used = systemBytes + await libraryBytes();
    return DeviceStorage(
      totalBytes: totalBytes,
      freeBytes: math.max(0, totalBytes - used),
    );
  }
}
