import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../domain/auth_failure.dart';
import 'auth_session.dart';
import 'pending_verification.dart';

@immutable
class CreateAccountState {
  const CreateAccountState({
    this.isSubmitting = false,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.failure,
    this.completed = false,
  });

  final bool isSubmitting;
  final FieldError? nameError;
  final FieldError? emailError;
  final FieldError? passwordError;
  final AuthFailure? failure;

  /// Đăng ký thành công, cần chuyển sang màn xác minh email.
  final bool completed;

  bool get hasErrors =>
      nameError != null ||
      emailError != null ||
      passwordError != null ||
      failure != null;
}

class CreateAccountController extends Notifier<CreateAccountState> {
  @override
  CreateAccountState build() => const CreateAccountState();

  void reset() => state = const CreateAccountState();

  void clearErrors() {
    if (state.hasErrors) {
      state = CreateAccountState(isSubmitting: state.isSubmitting);
    }
  }

  Future<void> submit({
    required String name,
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) return;

    final nameError = Validators.name(name);
    final emailError = Validators.email(email);
    final passwordError = Validators.newPassword(password);
    if (nameError != null || emailError != null || passwordError != null) {
      state = CreateAccountState(
        nameError: nameError,
        emailError: emailError,
        passwordError: passwordError,
      );
      return;
    }

    state = const CreateAccountState(isSubmitting: true);
    final normalizedEmail = Validators.normalizeEmail(email);
    try {
      await ref.read(authRepositoryProvider).signUp(
            name: Validators.normalizeName(name),
            email: normalizedEmail,
            password: password,
          );
      ref.read(pendingVerificationEmailProvider.notifier).set(normalizedEmail);
      state = const CreateAccountState(completed: true);
    } on AuthFailure catch (failure) {
      state = CreateAccountState(failure: failure);
    } catch (error) {
      state = CreateAccountState(failure: UnknownAuthFailure(error));
    }
  }
}

final createAccountControllerProvider =
    NotifierProvider<CreateAccountController, CreateAccountState>(
  CreateAccountController.new,
);
