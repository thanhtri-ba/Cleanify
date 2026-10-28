import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Mặc định dùng repository giả lập (chỉ để phát triển).
/// Thay bằng repository backend thật khi đã chọn nhà cung cấp.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => FakeAuthRepository());

sealed class AuthSession {
  const AuthSession();
}

final class SignedOut extends AuthSession {
  const SignedOut();
}

final class SignedIn extends AuthSession {
  const SignedIn(this.user);
  final AuthUser user;
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => const SignedOut();

  Future<void> restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).restoreSession();
      state = user == null ? const SignedOut() : SignedIn(user);
    } catch (_) {
      // Không khôi phục được phiên thì coi như chưa đăng nhập.
      state = const SignedOut();
    }
  }

  void signedIn(AuthUser user) => state = SignedIn(user);

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      // Dù gọi backend lỗi vẫn phải đăng xuất cục bộ.
      state = const SignedOut();
    }
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
