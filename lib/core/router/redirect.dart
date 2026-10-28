import 'app_routes.dart';

/// Quy tắc điều hướng thuần (không phụ thuộc Flutter) để dễ kiểm thử.
/// Trả về null nếu giữ nguyên vị trí, hoặc đường dẫn cần chuyển tới.
String? resolveRedirect({
  required String location,
  required bool onboardingSeen,
  required bool signedIn,
  required String? pendingVerificationEmail,
  required bool photoAccessPromptSeen,
}) {
  if (signedIn) {
    final isEntryRoute = location == AppRoutes.onboarding ||
        AppRoutes.authRoutes.contains(location);
    // Lần đầu vào app: hỏi quyền ảnh trước khi vào Home.
    if (isEntryRoute) {
      return photoAccessPromptSeen ? AppRoutes.home : AppRoutes.photoAccess;
    }
    if (location == AppRoutes.home && !photoAccessPromptSeen) {
      return AppRoutes.photoAccess;
    }
    return null;
  }

  if (!onboardingSeen) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  // Đã xem onboarding nhưng chưa đăng nhập: chỉ được ở các màn tài khoản.
  if (!AppRoutes.authRoutes.contains(location)) return AppRoutes.signIn;
  if (location == AppRoutes.verifyEmail && pendingVerificationEmail == null) {
    return AppRoutes.signIn;
  }
  return null;
}
