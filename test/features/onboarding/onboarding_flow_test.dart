import 'package:cleanify/app.dart';
import 'package:cleanify/core/storage/preferences_provider.dart';
import 'package:cleanify/features/auth/application/auth_session.dart';
import 'package:cleanify/features/auth/data/fake_auth_repository.dart';
import 'package:cleanify/features/onboarding/application/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
}) async {
  // Kích thước điện thoại (402x874 @3x) để bố cục không bị tràn.
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(latency: Duration.zero),
      ),
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
  return container;
}

void main() {
  testWidgets('đi qua 3 slide: Get Started, Continue, rồi Back', (tester) async {
    await pumpApp(tester);

    expect(find.text('A Cleaner Phone Starts Here'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Find & Remove Similar Photos'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Protection & Private Vault'), findsOneWidget);
    expect(find.text('Start Free Trial'), findsOneWidget);

    await tester.tap(find.text('Skip').first);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Skip chuyển sang sign in và ghi nhớ đã xem onboarding',
      (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(container.read(onboardingSeenProvider), isTrue);
    expect(
      container.read(sharedPreferencesProvider).getBool('onboarding_seen'),
      isTrue,
    );
  });

  testWidgets('"I already have an account" chuyển sang sign in',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Start Free Trial chuyển sang tạo tài khoản', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Free Trial'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('đã xem onboarding thì mở app vào thẳng sign in', (tester) async {
    await pumpApp(tester, prefsValues: {'onboarding_seen': true});

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('A Cleaner Phone Starts Here'), findsNothing);
  });
}
