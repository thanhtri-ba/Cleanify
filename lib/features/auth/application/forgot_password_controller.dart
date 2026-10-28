import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../domain/auth_failure.dart';
import 'auth_session.dart';

@immutable
class ForgotPasswordState {
  const ForgotPasswordState({
    this.isSubmitting = false,
    this.emailError,
    this.failure,
    this.sent = false,
  });

  final bool isSubmitting;
  final FieldError? emailError;
  final AuthFailure? failure;
  final bool sent;

  bool get hasErrors => emailError != null || failure != null;
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  void reset() => state = const ForgotPasswordState();

  void clearErrors() {
    if (state.hasErrors) {
      state = ForgotPasswordState(
        isSubmitting: state.isSubmitting,
        sent: state.sent,
      );
    }
  }

  Future<void> submit({required String email}) async {
    if (state.isSubmitting) return;

    final emailError = Validators.email(email);
    if (emailError != null) {
      state = ForgotPasswordState(emailError: emailError);
      return;
    }

    state = const ForgotPasswordState(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(email: Validators.normalizeEmail(email));
      state = const ForgotPasswordState(sent: true);
    } on AuthFailure catch (failure) {
      state = ForgotPasswordState(failure: failure);
    } catch (error) {
      state = ForgotPasswordState(failure: UnknownAuthFailure(error));
    }
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, ForgotPasswordState>(
  ForgotPasswordController.new,
);
