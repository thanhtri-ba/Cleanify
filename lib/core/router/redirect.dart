import 'app_routes.dart';

/// Quy tắc điều hướng thuần (không phụ thuộc Flutter) để dễ kiểm thử.
/// Trả về null nếu giữ nguyên vị trí, hoặc đường dẫn cần chuyển tới.
///
/// Không có đăng nhập: onboarding và màn xin quyền ảnh là hai bước bắt buộc
/// ở lần chạy đầu, sau đó vào thẳng app.
String? resolveRedirect({
  required String location,
  required bool onboardingSeen,
  required bool photoAccessPromptSeen,
}) {
  final isOnboarding = location == AppRoutes.onboarding ||
      location == AppRoutes.onboarding2 ||
      location == AppRoutes.onboarding3;
  final isOpen = location == AppRoutes.privacyPolicy;

  if (!onboardingSeen) {
    if (isOnboarding || isOpen) return null;
    return AppRoutes.onboarding;
  }

  if (isOnboarding) {
    return photoAccessPromptSeen ? AppRoutes.home : AppRoutes.fileAccess;
  }
  if (isOpen) return null;
  if (!photoAccessPromptSeen && location != AppRoutes.fileAccess) {
    return AppRoutes.fileAccess;
  }
  return null;
}
