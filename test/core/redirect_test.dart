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
  group('chưa đăng nhập, chưa xem onboarding', () {
    test('mọi màn đều bị đưa về onboarding', () {
      for (final route in [
        AppRoutes.signIn,
        AppRoutes.createAccount,
        AppRoutes.home,
      ]) {
        expect(redirect(route, seen: false), AppRoutes.onboarding,
            reason: route);
      }
    });

    test('đang ở onboarding thì giữ nguyên', () {
      expect(redirect(AppRoutes.onboarding, seen: false), isNull);
    });
  });

  group('chưa đăng nhập, đã xem onboarding', () {
    test('onboarding và home chuyển về sign in', () {
      expect(redirect(AppRoutes.onboarding), AppRoutes.signIn);
      expect(redirect(AppRoutes.home), AppRoutes.signIn);
    });

    test('các màn tài khoản được truy cập', () {
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
      expect(redirect(AppRoutes.verifyEmail, pending: 'a@example.com'), isNull);
    });
  });

  group('đã đăng nhập', () {
    test('onboarding và các màn tài khoản chuyển về home', () {
      for (final route in [
        AppRoutes.onboarding,
        AppRoutes.signIn,
        AppRoutes.createAccount,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
      ]) {
        expect(redirect(route, signedIn: true), AppRoutes.home,
            reason: route);
      }
    });

    test('home giữ nguyên, kể cả khi chưa xem onboarding', () {
      expect(redirect(AppRoutes.home, signedIn: true), isNull);
      expect(redirect(AppRoutes.home, signedIn: true, seen: false), isNull);
    });
  });

  group('quyền ảnh lần đầu', () {
    test('đăng nhập xong mà chưa qua màn quyền ảnh thì vào màn quyền ảnh', () {
      for (final route in [
        AppRoutes.onboarding,
        AppRoutes.signIn,
        AppRoutes.home,
      ]) {
        expect(
          redirect(route, signedIn: true, photoSeen: false),
          AppRoutes.photoAccess,
          reason: route,
        );
      }
    });

    test('màn quyền ảnh được giữ nguyên khi đã đăng nhập', () {
      expect(redirect(AppRoutes.photoAccess, signedIn: true, photoSeen: false),
          isNull);
      expect(redirect(AppRoutes.photoAccess, signedIn: true), isNull);
    });

    test('chưa đăng nhập thì mọi route không phải màn tài khoản về sign in', () {
      expect(redirect(AppRoutes.photoAccess), AppRoutes.signIn);
      expect(redirect('/bat-ky-route-nao'), AppRoutes.signIn);
    });
  });
}
