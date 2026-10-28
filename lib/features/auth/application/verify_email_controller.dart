import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_failure.dart';
import 'auth_session.dart';
import 'pending_verification.dart';

@immutable
class VerifyEmailState {
  const VerifyEmailState({
    this.cooldownSeconds = 0,
    this.isSending = false,
    this.justSent = false,
    this.failure,
  });

  final int cooldownSeconds;
  final bool isSending;
  final bool justSent;
  final AuthFailure? failure;

  bool get canResend => !isSending && cooldownSeconds == 0;
}

class VerifyEmailController extends Notifier<VerifyEmailState> {
  /// Thời gian chờ giữa hai lần gửi lại email xác minh.
  static const cooldown = 60;

  Timer? _timer;

  @override
  VerifyEmailState build() {
    ref.onDispose(() => _timer?.cancel());
    return const VerifyEmailState();
  }

  void reset() {
    _timer?.cancel();
    state = const VerifyEmailState();
  }

  Future<void> resend() async {
    final email = ref.read(pendingVerificationEmailProvider);
    if (email == null || !state.canResend) return;

    state = VerifyEmailState(
      cooldownSeconds: state.cooldownSeconds,
      isSending: true,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerificationEmail(email: email);
      state = const VerifyEmailState(cooldownSeconds: cooldown, justSent: true);
      _startCountdown();
    } on AuthFailure catch (failure) {
      state = VerifyEmailState(failure: failure);
    } catch (error) {
      state = VerifyEmailState(failure: UnknownAuthFailure(error));
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.cooldownSeconds - 1;
      if (left <= 0) {
        timer.cancel();
        state = VerifyEmailState(justSent: state.justSent);
        return;
      }
      state = VerifyEmailState(cooldownSeconds: left, justSent: state.justSent);
    });
  }
}

final verifyEmailControllerProvider =
    NotifierProvider<VerifyEmailController, VerifyEmailState>(
  VerifyEmailController.new,
);
