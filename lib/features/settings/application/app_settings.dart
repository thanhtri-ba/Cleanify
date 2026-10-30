import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';

class AppSettings {
  const AppSettings({this.notificationsEnabled = true});

  final bool notificationsEnabled;

  AppSettings copyWith({bool? notificationsEnabled}) => AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}

/// Tùy chọn người dùng, lưu bền vững bằng SharedPreferences.
class AppSettingsNotifier extends Notifier<AppSettings> {
  static const notificationsKey = 'settings_notifications_enabled';

  @override
  AppSettings build() => AppSettings(
        notificationsEnabled:
            ref.read(sharedPreferencesProvider).getBool(notificationsKey) ??
                true,
      );

  Future<void> setNotificationsEnabled(bool value) async {
    if (state.notificationsEnabled == value) return;
    state = state.copyWith(notificationsEnabled: value);
    await ref.read(sharedPreferencesProvider).setBool(notificationsKey, value);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
