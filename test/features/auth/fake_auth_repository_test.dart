import 'package:cleanify/features/auth/data/fake_auth_repository.dart';
import 'package:cleanify/features/auth/domain/auth_failure.dart';
import 'package:cleanify/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late FakeAuthRepository repo;

  setUp(() {
    now = DateTime(2026, 1, 1, 8);
    repo = FakeAuthRepository(
      latency: Duration.zero,
      verificationDelay: const Duration(seconds: 30),
      now: () => now,
    );
  });

  const password = 'Passw0rdX';

  test('đăng ký xong chưa đăng nhập được cho đến khi xác minh email', () async {
    await repo.signUp(name: 'An', email: 'An@Example.com', password: password);

    await expectLater(
      repo.signInWithEmail(email: 'an@example.com', password: password),
      throwsA(isA<EmailNotVerified>()),
    );

    now = now.add(const Duration(seconds: 31));
    final user =
        await repo.signInWithEmail(email: 'an@example.com', password: password);
    expect(user.email, 'an@example.com');
    expect(user.displayName, 'An');
    expect(user.emailVerified, isTrue);
  });

  test('sai mật khẩu và email không tồn tại cho cùng một lỗi', () async {
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);
    now = now.add(const Duration(minutes: 1));

    await expectLater(
      repo.signInWithEmail(email: 'an@example.com', password: 'WrongPass1'),
      throwsA(isA<InvalidCredentials>()),
    );
    await expectLater(
      repo.signInWithEmail(email: 'nobody@example.com', password: password),
      throwsA(isA<InvalidCredentials>()),
    );
  });

  test('đăng ký trùng email (không phân biệt hoa thường) bị từ chối', () async {
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);
    await expectLater(
      repo.signUp(name: 'Bao', email: 'AN@example.com', password: password),
      throwsA(isA<EmailAlreadyInUse>()),
    );
  });

  test('máy chủ cũng từ chối mật khẩu yếu', () async {
    await expectLater(
      repo.signUp(name: 'An', email: 'an@example.com', password: 'weak'),
      throwsA(isA<WeakPassword>()),
    );
  });

  test('đặt lại mật khẩu hoàn tất cả khi email không tồn tại', () async {
    await expectLater(
      repo.sendPasswordReset(email: 'nobody@example.com'),
      completes,
    );
  });

  test('gửi lại email xác minh làm link cũ hết hiệu lực', () async {
    await repo.signUp(name: 'An', email: 'an@example.com', password: password);

    now = now.add(const Duration(seconds: 20));
    await repo.resendVerificationEmail(email: 'an@example.com');

    // 31 giây kể từ lúc đăng ký: sẽ đã xác minh nếu không gửi lại.
    now = now.add(const Duration(seconds: 11));
    await expectLater(
      repo.signInWithEmail(email: 'an@example.com', password: password),
      throwsA(isA<EmailNotVerified>()),
    );

    now = now.add(const Duration(seconds: 20));
    await expectLater(
      repo.signInWithEmail(email: 'an@example.com', password: password),
      completes,
    );
  });

  test('gửi lại cho email không tồn tại vẫn hoàn tất', () async {
    await expectLater(
      repo.resendVerificationEmail(email: 'nobody@example.com'),
      completes,
    );
  });

  test('phiên đăng nhập được khôi phục rồi xóa khi đăng xuất', () async {
    expect(await repo.restoreSession(), isNull);

    final user = await repo.signInWithProvider(SocialProvider.google);
    expect((await repo.restoreSession())?.id, user.id);

    await repo.signOut();
    expect(await repo.restoreSession(), isNull);
  });
}
