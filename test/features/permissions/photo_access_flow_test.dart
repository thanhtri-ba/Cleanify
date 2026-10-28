import 'package:cleanify/features/home/presentation/home_page.dart';
import 'package:cleanify/app.dart';
import 'package:cleanify/core/storage/preferences_provider.dart';
import 'package:cleanify/features/auth/application/auth_session.dart';
import 'package:cleanify/features/auth/data/fake_auth_repository.dart';
import 'package:cleanify/features/permissions/application/media_access_controller.dart';
import 'package:cleanify/features/permissions/domain/media_access.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_media_access_gateway.dart';

/// Mở app đã đăng nhập sẵn (chưa qua màn quyền ảnh) rồi đăng nhập qua UI.
Future<ProviderContainer> pumpSignedIn(
  WidgetTester tester,
  FakeMediaAccessGateway gateway,
) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);

  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_seen': true});
  final prefs = await SharedPreferences.getInstance();

  final repo = FakeAuthRepository(
    latency: Duration.zero,
    verificationDelay: Duration.zero,
  );
  await repo.signUp(name: 'An', email: 'an@example.com', password: 'Passw0rdX');

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repo),
      mediaAccessGatewayProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const CleanifyApp(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, 'an@example.com');
  await tester.enterText(find.byType(TextField).last, 'Passw0rdX');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('đăng nhập lần đầu vào màn xin quyền ảnh', (tester) async {
    await pumpSignedIn(tester, FakeMediaAccessGateway());

    expect(find.text('Make room for memories'), findsOneWidget);
    expect(find.text('Next, iOS will ask what Cleanify can access.'),
        findsOneWidget);
  });

  testWidgets('Continue + cấp đủ quyền: vào Home và ghi nhớ đã qua màn này',
      (tester) async {
    final gateway = FakeMediaAccessGateway(requestResult: MediaAccess.granted);
    final container = await pumpSignedIn(tester, gateway);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(gateway.requestCalls, 1);
    expect(find.byKey(HomePage.pageKey), findsOneWidget);
    expect(container.read(photoAccessPromptSeenProvider), isTrue);
  });

  testWidgets('Not Now: vào Home mà không xin quyền', (tester) async {
    final gateway = FakeMediaAccessGateway();
    await pumpSignedIn(tester, gateway);

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(gateway.requestCalls, 0);
    expect(find.byKey(HomePage.pageKey), findsOneWidget);
  });

  testWidgets('cấp quyền giới hạn: hiện màn Limited rồi vào Home',
      (tester) async {
    final gateway = FakeMediaAccessGateway(requestResult: MediaAccess.limited);
    await pumpSignedIn(tester, gateway);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your selection, your control'), findsOneWidget);

    await tester.tap(find.text('Manage Selected Media'));
    await tester.pumpAndSettle();
    expect(gateway.manageLimitedCalls, 1);

    await tester.tap(find.text('Continue with Selected Media'));
    await tester.pumpAndSettle();
    expect(find.byKey(HomePage.pageKey), findsOneWidget);
  });

  testWidgets('bị từ chối: hiện màn Denied, mở Settings, đi tiếp không quyền',
      (tester) async {
    final gateway = FakeMediaAccessGateway(requestResult: MediaAccess.denied);
    await pumpSignedIn(tester, gateway);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Photo access is off'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(gateway.openSettingsCalls, 1);

    await tester.tap(find.text('Continue Without Access'));
    await tester.pumpAndSettle();
    expect(find.byKey(HomePage.pageKey), findsOneWidget);
  });

  testWidgets('đã bị từ chối sẵn từ trước (iOS): mở thẳng màn Denied',
      (tester) async {
    await pumpSignedIn(
      tester,
      FakeMediaAccessGateway(currentValue: MediaAccess.denied),
    );

    expect(find.text('Photo access is off'), findsOneWidget);
  });
}
