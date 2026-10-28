class StorageUnavailable implements Exception {
  const StorageUnavailable(this.message);

  final String message;

  @override
  String toString() => 'StorageUnavailable: $message';
}

class DeviceStorage {
  const DeviceStorage({required this.totalBytes, required this.freeBytes});

  final int totalBytes;
  final int freeBytes;

  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes).toInt();

  /// 0..1
  double get usedFraction => totalBytes == 0 ? 0 : usedBytes / totalBytes;
}

abstract interface class DeviceStorageSource {
  Future<DeviceStorage> read();
}
