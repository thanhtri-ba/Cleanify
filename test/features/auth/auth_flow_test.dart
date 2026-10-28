import 'package:cleanify/features/home/presentation/home_page.dart';
import 'package:cleanify/app.dart';
import 'package:cleanify/core/storage/preferences_provider.dart';
import 'package:cleanify/features/auth/application/auth_session.dart';
import 'package:cleanify/features/auth/data/fake_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpSignedOutApp(
  WidgetTester tester,
  FakeAuthRepository repo,
) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'onboarding_seen': true,
    'photo_access_prompt_seen': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repo),
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
  testWidgets('sign in với trường rỗng hiện thông báo lỗi', (tester) async {
    await pumpSignedOutApp(tester, FakeAuthRepository(latency: Duration.zero));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('sai mật khẩu hiện thông báo chung, không tiết lộ tài khoản',
      (tester) async {
    await pumpSignedOutApp(tester, FakeAuthRepository(latency: Duration.zero));

    await tester.enterText(
      find.byType(TextField).first,
      'nobody@example.com',
    );
    await tester.enterText(find.byType(TextField).last, 'Whatever1');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('đăng ký rồi chuyển sang màn xác minh với email đã che',
      (tester) async {
    final container = await pumpSignedOutApp(
      tester,
      FakeAuthRepository(
        latency: Duration.zero,
        verificationDelay: const Duration(hours: 1),
      ),
    );

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'An Nguyen');
    await tester.enterText(fields.at(1), 'example@gmail.com');
    await tester.enterText(fields.at(2), 'Passw0rdX');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('e••••@gmail.com'), findsOneWidget);
    expect(container.read(authSessionProvider), isA<SignedOut>());
  });

  testWidgets('mật khẩu yếu khi đăng ký hiện thông báo quy tắc',
      (tester) async {
    await pumpSignedOutApp(tester, FakeAuthRepository(latency: Duration.zero));

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'An');
    await tester.enterText(fields.at(1), 'an@example.com');
    await tester.enterText(fields.at(2), 'weak');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsNothing);
    expect(
      find.text(
        'Use at least 8 characters, with an uppercase letter, a lowercase letter and a number.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('đăng nhập thành công đưa vào màn Home', (tester) async {
    final repo = FakeAuthRepository(
      latency: Duration.zero,
      verificationDelay: Duration.zero,
    );
    await repo.signUp(
      name: 'An',
      email: 'an@example.com',
      password: 'Passw0rdX',
    );
    await pumpSignedOutApp(tester, repo);

    await tester.enterText(find.byType(TextField).first, 'an@example.com');
    await tester.enterText(find.byType(TextField).last, 'Passw0rdX');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byKey(HomePage.pageKey), findsOneWidget);
  });
}
