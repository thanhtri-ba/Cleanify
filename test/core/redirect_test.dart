import 'package:cleanify/core/router/app_routes.dart';
import 'package:cleanify/core/router/redirect.dart';
import 'package:flutter_test/flutter_test.dart';

String? redirect(
  String location, {
  bool seen = true,
  bool signedIn = false,
  String? pending,
  bool photoSeen = true,
}) =>
    resolveRedirect(
      location: location,
      onboardingSeen: seen,
      signedIn: signedIn,
      pendingVerificationEmail: pending,
      photoAccessPromptSeen: photoSeen,
    );

void main() {
  group('chưa xem onboarding, chưa đăng nhập', () {
    test('các màn onboarding được giữ nguyên', () {
      for (final route in [
        AppRoutes.onboarding,
        AppRoutes.onboarding2,
        AppRoutes.onboarding3,
      ]) {
        expect(redirect(route, seen: false), isNull, reason: route);
      }
    });

    test('màn đăng nhập mở được từ nút "I already have an account"', () {
      for (final route in [
        AppRoutes.signIn,
        AppRoutes.createAccount,
        AppRoutes.forgotPassword,
        AppRoutes.privacyPolicy,
      ]) {
        expect(redirect(route, seen: false), isNull, reason: route);
      }
    });

    test('verify email chỉ vào được khi có email đang chờ', () {
      expect(redirect(AppRoutes.verifyEmail, seen: false), AppRoutes.signIn);
      expect(
        redirect(AppRoutes.verifyEmail, seen: false, pending: 'a@example.com'),
        isNull,
      );
    });

    test('mọi màn khác bị đưa về onboarding', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.storage,
        AppRoutes.settings,
        '/bat-ky-route-nao',
      ]) {
        expect(redirect(route, seen: false), AppRoutes.onboarding,
            reason: route);
      }
    });
  });

  group('đã xem onboarding, chưa đăng nhập', () {
    test('vào thẳng các tab khi không cần tài khoản', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.storage,
        AppRoutes.settings,
        AppRoutes.scan,
      ]) {
        expect(redirect(route), isNull, reason: route);
      }
    });

    test('quay lại onboarding thì được đưa vào app', () {
      for (final route in [
        AppRoutes.onboarding,
        AppRoutes.onboarding2,
        AppRoutes.onboarding3,
      ]) {
        expect(redirect(route), AppRoutes.home, reason: route);
      }
    });

    test('chưa qua màn quyền ảnh thì bị đưa tới màn xin quyền', () {
      expect(
        redirect(AppRoutes.onboarding, photoSeen: false),
        AppRoutes.fileAccess,
      );
      expect(redirect(AppRoutes.home, photoSeen: false), AppRoutes.fileAccess);
      expect(redirect(AppRoutes.fileAccess, photoSeen: false), isNull);
      expect(redirect(AppRoutes.privacyPolicy, photoSeen: false), isNull);
    });

    test('các màn tài khoản vẫn mở', () {
      for (final route in [
        AppRoutes.signIn,
        AppRoutes.createAccount,
        AppRoutes.forgotPassword,
      ]) {
        expect(redirect(route), isNull, reason: route);
      }
    });

    test('verify email chỉ vào được khi có email đang chờ', () {
      expect(redirect(AppRoutes.verifyEmail), AppRoutes.signIn);
      expect(
        redirect(AppRoutes.verifyEmail, pending: 'a@example.com'),
        isNull,
      );
    });
  });

  group('đã đăng nhập', () {
    test('onboarding và các màn tài khoản chuyển về home', () {
      for (final route in [
        AppRoutes.onboarding,
        AppRoutes.onboarding2,
        AppRoutes.onboarding3,
        AppRoutes.signIn,
        AppRoutes.createAccount,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
      ]) {
        expect(redirect(route, signedIn: true), AppRoutes.home, reason: route);
      }
    });

    test('chưa qua màn quyền ảnh thì về màn xin quyền', () {
      expect(
        redirect(AppRoutes.onboarding, signedIn: true, photoSeen: false),
        AppRoutes.fileAccess,
      );
      expect(
        redirect(AppRoutes.home, signedIn: true, photoSeen: false),
        AppRoutes.fileAccess,
      );
      expect(
        redirect(AppRoutes.fileAccess, signedIn: true, photoSeen: false),
        isNull,
      );
    });

    test('các tab giữ nguyên khi đã qua màn quyền ảnh', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.storage,
        AppRoutes.settings,
      ]) {
        expect(redirect(route, signedIn: true), isNull, reason: route);
      }
    });

    test('đăng nhập xong bỏ qua onboarding chưa xem', () {
      expect(redirect(AppRoutes.home, seen: false, signedIn: true), isNull);
      expect(redirect(AppRoutes.settings, seen: false, signedIn: true), isNull);
    });
  });
}
