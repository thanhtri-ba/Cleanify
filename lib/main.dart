import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/storage/preferences_provider.dart';
import 'features/scan/application/scan_providers.dart';
import 'features/scan/background/background_scan.dart';
import 'features/scan/data/opencv_features.dart';
import 'features/scan/data/sqflite_hash_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hashes = await SqfliteHashStore.open(
    '${await getDatabasesPath()}/cleanify_hashes.db',
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      hashStoreProvider.overrideWithValue(hashes),
      featureMatcherProvider.overrideWithValue(const OpenCvFeatureMatcher()),
    ],
  );
  // Quét nền: đăng ký tác vụ và lên lịch khi đang sạc (mặc định bật).
  try {
    await Workmanager().initialize(backgroundScanDispatcher);
    await scheduleBackgroundScan(
      enabled: prefs.getBool(backgroundScanEnabledKey) ?? true,
    );
  } catch (_) {
    // Quét nền không khởi tạo được thì app vẫn chạy bình thường.
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CleanifyApp(),
    ),
  );
}
