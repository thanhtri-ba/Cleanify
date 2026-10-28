import 'package:cleanify/features/auth/application/auth_session.dart';
import 'package:cleanify/features/auth/application/pending_verification.dart';
import 'package:cleanify/features/auth/application/verify_email_controller.dart';
import 'package:cleanify/features/auth/data/fake_auth_repository.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gửi lại: bắt đầu đếm ngược, chặn gửi trong thời gian chờ', () {
    fakeAsync((async) {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(latency: Duration.zero),
          ),
        ],
      );
      container
          .read(pendingVerificationEmailProvider.notifier)
          .set('a@example.com');
      final controller = container.read(verifyEmailControllerProvider.notifier);

      controller.resend();
      async.flushMicrotasks();
      var state = container.read(verifyEmailControllerProvider);
      expect(state.cooldownSeconds, VerifyEmailController.cooldown);
      expect(state.justSent, isTrue);
      expect(state.canResend, isFalse);

      async.elapse(const Duration(seconds: 10));
      state = container.read(verifyEmailControllerProvider);
      expect(state.cooldownSeconds, VerifyEmailController.cooldown - 10);

      // Bấm khi đang chờ: bị bỏ qua, đồng hồ không bị đặt lại.
      controller.resend();
      async.flushMicrotasks();
      state = container.read(verifyEmailControllerProvider);
      expect(state.cooldownSeconds, VerifyEmailController.cooldown - 10);

      async.elapse(const Duration(seconds: 50));
      state = container.read(verifyEmailControllerProvider);
      expect(state.cooldownSeconds, 0);
      expect(state.canResend, isTrue);

      container.dispose();
    });
  });

  test('không có email đang chờ thì không gửi', () {
    fakeAsync((async) {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(latency: Duration.zero),
          ),
        ],
      );

      container.read(verifyEmailControllerProvider.notifier).resend();
      async.flushMicrotasks();

      final state = container.read(verifyEmailControllerProvider);
      expect(state.cooldownSeconds, 0);
      expect(state.justSent, isFalse);

      container.dispose();
    });
  });
}
