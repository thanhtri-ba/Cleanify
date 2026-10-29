 import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';

/// Đã xem onboarding chưa. Lưu bền vững bằng SharedPreferences.
class OnboardingSeenNotifier extends Notifier<bool> {
  static const storageKey = 'onboarding_seen';

  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(storageKey) ?? false;

  Future<void> complete() async {
    if (state) return;
    state = true; // cập nhật ngay để router chuyển màn không bị trễ
    await ref.read(sharedPreferencesProvider).setBool(storageKey, true);
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);
