import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';
import 'auth_session.dart';

@immutable
class SocialSignInState {
  const SocialSignInState({this.inProgress, this.failure});

  final SocialProvider? inProgress;
  final AuthFailure? failure;
}

class SocialSignInController extends Notifier<SocialSignInState> {
  @override
  SocialSignInState build() => const SocialSignInState();

  void reset() => state = const SocialSignInState();

  Future<void> signIn(SocialProvider provider) async {
    if (state.inProgress != null) return;
    state = SocialSignInState(inProgress: provider);
    try {
      final user =
          await ref.read(authRepositoryProvider).signInWithProvider(provider);
      ref.read(authSessionProvider.notifier).signedIn(user);
      state = const SocialSignInState();
    } on UserCancelled {
      state = const SocialSignInState(); // hủy chủ động: không báo lỗi
    } on AuthFailure catch (failure) {
      state = SocialSignInState(failure: failure);
    } catch (error) {
      state = SocialSignInState(failure: UnknownAuthFailure(error));
    }
  }
}

final socialSignInControllerProvider =
    NotifierProvider<SocialSignInController, SocialSignInState>(
  SocialSignInController.new,
);
