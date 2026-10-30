import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import '../data/opencv_features.dart';
import '../data/photo_manager_media_source.dart';
import '../data/sqflite_hash_store.dart';
import '../domain/media_scanner.dart';
import '../domain/scan_models.dart';

/// Mã tác vụ quét nền. Phải khớp với `BGTaskSchedulerPermittedIdentifiers`
/// trong Info.plist và với AppDelegate.
const backgroundScanIdentifier = 'com.thanhtri.cleanify.backgroundscan';
const backgroundScanTaskName = 'cleanify.backgroundScan';

/// Khóa lưu trong SharedPreferences.
const backgroundScanEnabledKey = 'background_scan_enabled';
const backgroundScanLastRunKey = 'background_scan_last_run_ms';
const backgroundScanDuplicatesKey = 'background_scan_duplicates';
const backgroundScanSimilarKey = 'background_scan_similar';

/// Điểm vào của isolate nền (iOS). Không được xoá hoặc đổi tên.
@pragma('vm:entry-point')
void backgroundScanDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundScanTaskName) return true;
    return runBackgroundScan();
  });
}

/// Lên lịch quét nền khi đang sạc. Gọi khi app khởi động và khi người dùng bật
/// lại quét nền. Trên simulator iOS, lịch chỉ chạy khi kích hoạt bằng LLDB.
Future<void> scheduleBackgroundScan({required bool enabled}) async {
  final workmanager = Workmanager();
  if (!enabled) {
    await workmanager.cancelByUniqueName(backgroundScanIdentifier);
    return;
  }
  await workmanager.registerProcessingTask(
    backgroundScanIdentifier,
    backgroundScanTaskName,
    constraints: Constraints(requiresCharging: true),
  );
}

/// Chạy một lượt quét ở nền. Trả về false nếu cần thử lại sau.
Future<bool> runBackgroundScan() async {
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool(backgroundScanEnabledKey) ?? true)) return true;

  final permission = await PhotoManager.getPermissionState(
    requestOption: const PermissionRequestOption(),
  );
  // Không có quyền thì không hỏi trong nền; người dùng cần mở app để cấp quyền.
  if (permission != PermissionState.authorized &&
      permission != PermissionState.limited) {
    return true;
  }

  final store = await SqfliteHashStore.open(
    '${await getDatabasesPath()}/cleanify_hashes.db',
  );
  try {
    final outcome = await MediaScanner(
      PhotoManagerMediaSource(),
      config: const ScanConfig(),
      store: store,
      matcher: const OpenCvFeatureMatcher(),
    ).run(cancel: CancelToken());
    if (outcome.end != ScanEnd.completed) return false;
    await prefs.setInt(backgroundScanLastRunKey,
        DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(
      backgroundScanDuplicatesKey,
      outcome.result.duplicateGroups.length,
    );
    await prefs.setInt(
      backgroundScanSimilarKey,
      outcome.result.similarGroups.length,
    );
    return true;
  } finally {
    await store.close();
  }
}
