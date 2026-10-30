import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';

/// Chế độ giao diện người dùng chọn (lưu trữ; giao diện hiện chưa đổi theo).
enum AppearanceMode { system, light, dark }

/// Nhóm quét có thể bật/tắt trong Scan Preferences.
enum ScanOption { junkFiles, largeFiles, duplicatePhotos, downloads }

class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.appearance = AppearanceMode.system,
    this.scanOptions = const {
      ScanOption.junkFiles,
      ScanOption.largeFiles,
      ScanOption.duplicatePhotos,
      ScanOption.downloads,
    },
  });

  final bool notificationsEnabled;
  final AppearanceMode appearance;
  final Set<ScanOption> scanOptions;

  bool isScanOn(ScanOption option) => scanOptions.contains(option);

  AppSettings copyWith({
    bool? notificationsEnabled,
    AppearanceMode? appearance,
    Set<ScanOption>? scanOptions,
  }) =>
      AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        appearance: appearance ?? this.appearance,
        scanOptions: scanOptions ?? this.scanOptions,
      );
}

/// Tùy chọn người dùng, lưu bền vững bằng SharedPreferences.
class AppSettingsNotifier extends Notifier<AppSettings> {
  static const notificationsKey = 'settings_notifications_enabled';
  static const appearanceKey = 'settings_appearance';
  static const scanOptionsKey = 'settings_scan_options';

  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final storedScan = prefs.getStringList(scanOptionsKey);
    return AppSettings(
      notificationsEnabled: prefs.getBool(notificationsKey) ?? true,
      appearance: AppearanceMode.values.asNameMap()[
              prefs.getString(appearanceKey)] ??
          AppearanceMode.system,
      scanOptions: storedScan == null
          ? const AppSettings().scanOptions
          : {
              for (final o in ScanOption.values)
                if (storedScan.contains(o.name)) o,
            },
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (state.notificationsEnabled == value) return;
    state = state.copyWith(notificationsEnabled: value);
    await ref.read(sharedPreferencesProvider).setBool(notificationsKey, value);
  }

  Future<void> setAppearance(AppearanceMode mode) async {
    if (state.appearance == mode) return;
    state = state.copyWith(appearance: mode);
    await ref.read(sharedPreferencesProvider).setString(appearanceKey, mode.name);
  }

  Future<void> setScanOption(ScanOption option, bool on) async {
    final next = {...state.scanOptions};
    if (on) {
      next.add(option);
    } else {
      next.remove(option);
    }
    state = state.copyWith(scanOptions: next);
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(scanOptionsKey, [for (final o in next) o.name]);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
