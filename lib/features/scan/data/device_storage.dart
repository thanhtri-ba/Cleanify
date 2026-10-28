import 'package:disk_space_plus/disk_space_plus.dart';

import '../domain/device_storage.dart';

/// Đọc dung lượng thiết bị bằng `disk_space_plus` (đơn vị plugin trả về: MB).
class DiskSpaceStorageSource implements DeviceStorageSource {
  const DiskSpaceStorageSource();

  static const double _bytesPerMb = 1000 * 1000;

  @override
  Future<DeviceStorage> read() async {
    final plugin = DiskSpacePlus();
    final totalMb = await plugin.getTotalDiskSpace;
    final freeMb = await plugin.getFreeDiskSpace;
    if (totalMb == null || freeMb == null || totalMb <= 0) {
      throw const StorageUnavailable('Device storage is unavailable');
    }
    return DeviceStorage(
      totalBytes: (totalMb * _bytesPerMb).round(),
      freeBytes: (freeMb * _bytesPerMb).round(),
    );
  }
}
