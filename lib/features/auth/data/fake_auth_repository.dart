import '../../../core/utils/validators.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// CHỈ DÙNG ĐỂ PHÁT TRIỂN: lưu tài khoản trong bộ nhớ (mất khi tắt app), mật
/// khẩu lưu dạng thô. Phải thay bằng repository backend thật trước khi phát
/// hành. Mô phỏng việc người dùng bấm link xác minh sau [verificationDelay].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.latency = const Duration(milliseconds: 600),
    this.verificationDelay = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration latency;
  final Duration verificationDelay;
  final DateTime Function() _now;

  final Map<String, _Account> _accounts = {};
  AuthUser? _current;
  int _nextId = 1;

  Future<void> _simulateLatency() => latency == Duration.zero
      ? Future<void>.value()
      : Future<void>.delayed(latency);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _simulateLatency();
    final account = _accounts[Validators.normalizeEmail(email)];
    if (account == null || account.password != password) {
      throw const InvalidCredentials();
    }
    if (!account.isVerified(_now())) {
      throw EmailNotVerified(account.email);
    }
    return _current = account.toUser();
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _simulateLatency();
    final key = Validators.normalizeEmail(email);
    if (Validators.newPassword(password) != null) throw const WeakPassword();
    if (_accounts.containsKey(key)) throw const EmailAlreadyInUse();
    _accounts[key] = _Account(
      id: 'user-${_nextId++}',
      email: key,
      name: Validators.normalizeName(name),
      password: password,
      verifiedAt: _now().add(verificationDelay),
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await _simulateLatency();
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    await _simulateLatency();
    final account = _accounts[Validators.normalizeEmail(email)];
    if (account != null && !account.isVerified(_now())) {
      // Gửi lại email mới: link cũ coi như hết hiệu lực, đếm lại từ đầu.
      account.verifiedAt = _now().add(verificationDelay);
    }
  }

  @override
  Future<AuthUser> signInWithProvider(SocialProvider provider) async {
    await _simulateLatency();
    return _current = AuthUser(
      id: 'social-${provider.name}',
      email: '${provider.name}.user@example.com',
      displayName: 'Demo ${provider.name}',
      emailVerified: true,
    );
  }

  @override
  Future<AuthUser?> restoreSession() async => _current;

  @override
  Future<void> signOut() async {
    _current = null;
  }
}

class _Account {
  _Account({
    required this.id,
    required this.email,
    required this.name,
    required this.password,
    required this.verifiedAt,
  });

  final String id;
  final String email;
  final String name;
  final String password;
  DateTime verifiedAt;

  bool isVerified(DateTime now) => !now.isBefore(verifiedAt);

  AuthUser toUser() => AuthUser(
        id: id,
        email: email,
        displayName: name,
        emailVerified: true,
      );
}
