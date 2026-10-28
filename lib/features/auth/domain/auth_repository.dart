import 'auth_user.dart';

abstract interface class AuthRepository {
  /// Ném [EmailNotVerified] nếu đúng mật khẩu nhưng chưa xác minh email.
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Tạo tài khoản và gửi email xác minh. Không tự đăng nhập.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Luôn hoàn tất thành công dù email có tồn tại hay không (chống dò tài khoản).
  Future<void> sendPasswordReset({required String email});

  Future<void> resendVerificationEmail({required String email});

  Future<AuthUser> signInWithProvider(SocialProvider provider);

  Future<AuthUser?> restoreSession();

  Future<void> signOut();
}
