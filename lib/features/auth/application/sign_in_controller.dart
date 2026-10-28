import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../domain/auth_failure.dart';
import 'auth_session.dart';
import 'pending_verification.dart';

@immutable
class SignInState {
  const SignInState({
    this.isSubmitting = false,
    this.emailError,
    this.passwordError,
    this.failure,
    this.needsVerification = false,
  });

  final bool isSubmitting;
  final FieldError? emailError;
  final FieldError? passwordError;
  final AuthFailure? failure;
  final bool needsVerification;

  bool get hasErrors =>
      emailError != null || passwordError != null || failure != null;
}

class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  void reset() => state = const SignInState();

  /// Xóa lỗi khi người dùng bắt đầu sửa lại nội dung.
  void clearErrors() {
    if (state.hasErrors) {
      state = SignInState(isSubmitting: state.isSubmitting);
    }
  }

  Future<void> submit({required String email, required String password}) async {
    if (state.isSubmitting) return; // chặn bấm hai lần

    final emailError = Validators.email(email);
    final passwordError = Validators.requiredPassword(password);
    if (emailError != null || passwordError != null) {
      state = SignInState(emailError: emailError, passwordError: passwordError);
      return;
    }

    state = const SignInState(isSubmitting: true);
    final normalizedEmail = Validators.normalizeEmail(email);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithEmail(
            email: normalizedEmail,
            password: password,
          );
      ref.read(authSessionProvider.notifier).signedIn(user);
      state = const SignInState();
    } on EmailNotVerified catch (e) {
      ref.read(pendingVerificationEmailProvider.notifier).set(e.email);
      state = const SignInState(needsVerification: true);
    } on AuthFailure catch (failure) {
      state = SignInState(failure: failure);
    } catch (error) {
      state = SignInState(failure: UnknownAuthFailure(error));
    }
  }
}

final signInControllerProvider =
    NotifierProvider<SignInController, SignInState>(SignInController.new);
