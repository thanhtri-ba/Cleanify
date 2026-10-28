/// Các lỗi xác thực mà UI cần phân biệt. Repository phải dịch lỗi của backend
/// (Supabase, Firebase...) sang các lỗi này, UI không biết backend cụ thể.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

/// Sai email hoặc sai mật khẩu (cố ý không phân biệt để tránh dò tài khoản).
final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

final class EmailAlreadyInUse extends AuthFailure {
  const EmailAlreadyInUse();
}

final class EmailNotVerified extends AuthFailure {
  const EmailNotVerified(this.email);
  final String email;
}

final class WeakPassword extends AuthFailure {
  const WeakPassword();
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

final class TooManyRequests extends AuthFailure {
  const TooManyRequests();
}

/// Người dùng tự hủy (ví dụ đóng cửa sổ đăng nhập Google), không phải lỗi.
final class UserCancelled extends AuthFailure {
  const UserCancelled();
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([this.cause]);
  final Object? cause;
}
