import 'app_routes.dart';

/// Quy tắc điều hướng thuần (không phụ thuộc Flutter) để dễ kiểm thử.
/// Trả về null nếu giữ nguyên vị trí, hoặc đường dẫn cần chuyển tới.
///
/// Đăng nhập là tùy chọn: người dùng có thể dùng app mà không cần tài khoản.
/// Onboarding và màn xin quyền ảnh vẫn là hai bước bắt buộc ở lần chạy đầu.
String? resolveRedirect({
  required String location,
  required bool onboardingSeen,
  required bool signedIn,
  required String? pendingVerificationEmail,
  required bool photoAccessPromptSeen,
}) {
  final isOnboarding = location == AppRoutes.onboarding ||
      location == AppRoutes.onboarding2 ||
      location == AppRoutes.onboarding3;
  final isAuth = AppRoutes.authRoutes.contains(location);
  final isOpen = location == AppRoutes.privacyPolicy;

  if (signedIn) {
    // Đã đăng nhập thì bỏ qua onboarding và các màn tài khoản.
    if (isOnboarding || isAuth) {
      return photoAccessPromptSeen ? AppRoutes.home : AppRoutes.fileAccess;
    }
    if (!photoAccessPromptSeen && location != AppRoutes.fileAccess && !isOpen) {
      return AppRoutes.fileAccess;
    }
    return null;
  }

  if (!onboardingSeen) {
    if (isOnboarding || isOpen) return null;
    if (isAuth) {
      // Chỉ vào màn xác minh email khi thật sự có email đang chờ.
      if (location == AppRoutes.verifyEmail &&
          pendingVerificationEmail == null) {
        return AppRoutes.signIn;
      }
      return null;
    }
    return AppRoutes.onboarding;
  }

  // Đã xem onboarding, chưa đăng nhập: vào thẳng app được (auth tùy chọn).
  if (isOnboarding) {
    return photoAccessPromptSeen ? AppRoutes.home : AppRoutes.fileAccess;
  }
  if (location == AppRoutes.verifyEmail && pendingVerificationEmail == null) {
    return AppRoutes.signIn;
  }
  if (isAuth || isOpen) return null;
  if (!photoAccessPromptSeen && location != AppRoutes.fileAccess) {
    return AppRoutes.fileAccess;
  }
  return null;
}
