import 'package:cleanify/core/router/app_routes.dart';
import 'package:cleanify/core/router/redirect.dart';
import 'package:flutter_test/flutter_test.dart';

String? redirect(String location, {bool seen = true, bool photoSeen = true}) =>
    resolveRedirect(
      location: location,
      onboardingSeen: seen,
      photoAccessPromptSeen: photoSeen,
    );

void main() {
  group('chưa xem onboarding', () {
    test('các màn onboarding được giữ nguyên', () {
      for (final route in [
        AppRoutes.onboarding,
        AppRoutes.onboarding2,
        AppRoutes.onboarding3,
      ]) {
        expect(redirect(route, seen: false), isNull, reason: route);
      }
    });

    test('màn khác đưa về onboarding', () {
      expect(redirect(AppRoutes.home, seen: false), AppRoutes.onboarding);
      expect(redirect(AppRoutes.fileAccess, seen: false), AppRoutes.onboarding);
    });

    test('privacy policy luôn mở được', () {
      expect(redirect(AppRoutes.privacyPolicy, seen: false), isNull);
    });
  });

  group('đã xem onboarding', () {
    test('onboarding chuyển thẳng vào app', () {
      expect(redirect(AppRoutes.onboarding), AppRoutes.home);
      expect(
        redirect(AppRoutes.onboarding, photoSeen: false),
        AppRoutes.fileAccess,
      );
    });

    test('chưa xin quyền ảnh thì chuyển tới fileAccess', () {
      expect(redirect(AppRoutes.home, photoSeen: false), AppRoutes.fileAccess);
      expect(redirect(AppRoutes.fileAccess, photoSeen: false), isNull);
    });

    test('đã xin quyền thì vào app bình thường', () {
      expect(redirect(AppRoutes.home), isNull);
      expect(redirect(AppRoutes.settings), isNull);
    });

    test('privacy policy luôn mở được', () {
      expect(redirect(AppRoutes.privacyPolicy, photoSeen: false), isNull);
    });
  });
}
