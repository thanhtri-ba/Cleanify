import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/preferences_provider.dart';
import 'features/auth/application/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Khôi phục phiên đăng nhập trước khi router quyết định màn hình đầu tiên.
  await container.read(authSessionProvider.notifier).restore();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CleanifyApp(),
    ),
  );
}
