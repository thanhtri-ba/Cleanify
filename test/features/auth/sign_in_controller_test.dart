import 'package:cleanify/core/utils/validators.dart';
import 'package:cleanify/features/auth/application/auth_session.dart';
import 'package:cleanify/features/auth/application/pending_verification.dart';
import 'package:cleanify/features/auth/application/sign_in_controller.dart';
import 'package:cleanify/features/auth/data/fake_auth_repository.dart';
import 'package:cleanify/features/auth/domain/auth_failure.dart';
import 'package:cleanify/features/auth/domain/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingRepository extends FakeAuthRepository {
  _CountingRepository({super.latency, super.verificationDelay});

  int signInCalls = 0;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    signInCalls++;
    return super.signInWithEmail(email: email, password: password);
  }
}

ProviderContainer makeContainer(FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const password = 'Passw0rdX';

  test('trường rỗng báo lỗi và không gọi repository', () async {
    final repo = _CountingRepository(latency: Duration.zero);
    final container = makeContainer(repo);

    await container
        .read(signInControllerProvider.notifier)
        .submit(email: '', password: '');

    final state = container.read(signInControllerProvider);
    expect(state.emailError, FieldError.emailRequired);
    expect(state.passwordError, FieldError.passwordRequired);
    expect(state.isSubmitting, isFalse);
    expect(repo.signInCalls, 0);
  });

  test('email sai định dạng báo lỗi email', () async {
    final repo = _CountingRepository(latency: Duration.zero);
    final container = makeContainer(repo);

    await container
        .read(signInControllerProvider.notifier)
        .submit(email: 'not-an-email', password: password);

    expect(
      container.read(signInControllerProvider).emailError,
      FieldError.emailInvalid,
    );
    expect(repo.signInCalls, 0);
  });

  test('đăng nhập thành công cập nhật phiên', () async {
    final repo = _CountingRepository(
      latency: Duration.zero,
      verificationDelay: Duration.zero,
    );
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);
    final container = makeContainer(repo);

    await container
        .read(signInControllerProvider.notifier)
        .submit(email: ' AN@example.com ', password: password);

    final session = container.read(authSessionProvider);
    expect(session, isA<SignedIn>());
    expect((session as SignedIn).user.email, 'an@example.com');
    expect(container.read(signInControllerProvider).hasErrors, isFalse);
  });

  test('chưa xác minh email: lưu email chờ và yêu cầu chuyển màn', () async {
    final repo = _CountingRepository(
      latency: Duration.zero,
      verificationDelay: const Duration(hours: 1),
    );
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);
    final container = makeContainer(repo);

    await container
        .read(signInControllerProvider.notifier)
        .submit(email: 'an@example.com', password: password);

    expect(container.read(signInControllerProvider).needsVerification, isTrue);
    expect(container.read(pendingVerificationEmailProvider), 'an@example.com');
    expect(container.read(authSessionProvider), isA<SignedOut>());
  });

  test('sai mật khẩu giữ trạng thái chưa đăng nhập và báo lỗi', () async {
    final repo = _CountingRepository(
      latency: Duration.zero,
      verificationDelay: Duration.zero,
    );
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);
    final container = makeContainer(repo);

    await container
        .read(signInControllerProvider.notifier)
        .submit(email: 'an@example.com', password: 'WrongPass1');

    final state = container.read(signInControllerProvider);
    expect(state.failure, isA<InvalidCredentials>());
    expect(state.isSubmitting, isFalse);
    expect(container.read(authSessionProvider), isA<SignedOut>());
  });

  test('bấm hai lần liên tiếp chỉ gọi repository một lần', () async {
    final repo = _CountingRepository(
      latency: const Duration(milliseconds: 20),
      verificationDelay: Duration.zero,
    );
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);
    final container = makeContainer(repo);
    final controller = container.read(signInControllerProvider.notifier);

    final first = controller.submit(email: 'an@example.com', password: password);
    expect(container.read(signInControllerProvider).isSubmitting, isTrue);
    await controller.submit(email: 'an@example.com', password: password);
    await first;

    expect(repo.signInCalls, 1);
  });

  test('clearErrors xóa lỗi khi người dùng sửa lại', () async {
    final repo = _CountingRepository(latency: Duration.zero);
    final container = makeContainer(repo);
    final controller = container.read(signInControllerProvider.notifier);

    await controller.submit(email: '', password: '');
    expect(container.read(signInControllerProvider).hasErrors, isTrue);

    controller.clearErrors();
    expect(container.read(signInControllerProvider).hasErrors, isFalse);
  });
}
