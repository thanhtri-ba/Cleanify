import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_session.dart';
import '../application/sign_in_controller.dart';
import '../application/social_sign_in_controller.dart';
import '../domain/auth_user.dart';
import 'auth_parts.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(signInControllerProvider.notifier).reset();
      ref.read(socialSignInControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearErrors() {
    ref.read(signInControllerProvider.notifier).clearErrors();
    ref.read(socialSignInControllerProvider.notifier).reset();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(signInControllerProvider.notifier).submit(
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (ref.read(authSessionProvider) is SignedIn) {
      context.go(AppRoutes.home);
      return;
    }
    if (ref.read(signInControllerProvider).needsVerification) {
      context.go(AppRoutes.verifyEmail);
    }
  }

  Future<void> _social(SocialProvider provider) async {
    await ref.read(socialSignInControllerProvider.notifier).signIn(provider);
    if (!mounted) return;
    if (ref.read(authSessionProvider) is SignedIn) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final social = ref.watch(socialSignInControllerProvider);
    final failure = state.failure ?? social.failure;

    return AuthScaffold(
      title: AppStrings.signInTitle,
      subtitle: AppStrings.signInSubtitle,
      onBack: context.canPop() ? () => context.pop() : null,
      children: [
        AuthTextField(
          label: AppStrings.emailLabel,
          controller: _email,
          hint: AppStrings.emailHint,
          prefixIcon: AppAssets.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          error: fieldErrorMessage(state.emailError),
          onChanged: (_) => _clearErrors(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: AppStrings.passwordLabel,
          controller: _password,
          hint: AppStrings.passwordHintSignIn,
          prefixIcon: AppAssets.lockKeyhole,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          error: fieldErrorMessage(state.passwordError),
          onChanged: (_) => _clearErrors(),
          onSubmitted: (_) => _submit(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(AppStrings.forgotPasswordLink, style: AppText.link),
          ),
        ),
        AuthErrorBanner(message: authFailureMessage(failure)),
        const SizedBox(height: 8),
        PrimaryButton(
          label: AppStrings.signInButton,
          height: 56,
          radius: 18,
          color: Colors.black,
          labelStyle: AppText.permPrimary,
          shadows: const [],
          isLoading: state.isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        AuthSocialButtons(
          onSelected: _social,
          enabled: social.inProgress == null && !state.isSubmitting,
        ),
        const SizedBox(height: 24),
        AuthFooterLink(
          prompt: AppStrings.newToCleanify,
          label: AppStrings.createAccountLink,
          onTap: () => context.push(AppRoutes.createAccount),
        ),
      ],
    );
  }
}
