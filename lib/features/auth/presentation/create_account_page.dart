import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_session.dart';
import '../application/create_account_controller.dart';
import '../application/social_sign_in_controller.dart';
import '../domain/auth_user.dart';
import 'auth_parts.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TapGestureRecognizer _termsLink;
  late final TapGestureRecognizer _privacyLink;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _termsLink = TapGestureRecognizer()..onTap = _showTermsUnavailable;
    _privacyLink = TapGestureRecognizer()..onTap = _openPrivacy;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(createAccountControllerProvider.notifier).reset();
      ref.read(socialSignInControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _termsLink.dispose();
    _privacyLink.dispose();
    super.dispose();
  }

  void _showTermsUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.termsUnavailable),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _openPrivacy() {
    if (mounted) context.push(AppRoutes.privacyPolicy);
  }

  void _clearErrors() {
    ref.read(createAccountControllerProvider.notifier).clearErrors();
    ref.read(socialSignInControllerProvider.notifier).reset();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(createAccountControllerProvider.notifier).submit(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (ref.read(createAccountControllerProvider).completed) {
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

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createAccountControllerProvider);
    final social = ref.watch(socialSignInControllerProvider);
    final failure = state.failure ?? social.failure;
    final linkStyle = AppText.custom(
      12,
      FontWeight.w600,
      AppColors.textPrimary,
      lineHeight: 18,
    );

    return AuthScaffold(
      title: AppStrings.createTitle,
      subtitle: AppStrings.createSubtitle,
      onBack: context.canPop() ? () => context.pop() : null,
      children: [
        AuthTextField(
          label: AppStrings.fullNameLabel,
          controller: _name,
          hint: AppStrings.fullNameHint,
          prefixIcon: AppAssets.userRound,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          error: fieldErrorMessage(state.nameError),
          onChanged: (_) => _clearErrors(),
        ),
        const SizedBox(height: 16),
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
          hint: AppStrings.passwordHintCreate,
          helper: AppStrings.passwordRule,
          prefixIcon: AppAssets.lockKeyhole,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          error: fieldErrorMessage(state.passwordError),
          onChanged: (_) => _clearErrors(),
          onSubmitted: (_) => _submit(),
        ),
        AuthErrorBanner(message: authFailureMessage(failure)),
        const SizedBox(height: 16),
        PrimaryButton(
          label: AppStrings.createButton,
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
          prompt: AppStrings.alreadyHaveAccount,
          label: AppStrings.signInLink,
          onTap: _backToSignIn,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: AppStrings.termsPrefix),
              TextSpan(
                text: AppStrings.termsOfService,
                style: linkStyle,
                recognizer: _termsLink,
              ),
              const TextSpan(text: AppStrings.termsMiddle),
              TextSpan(
                text: AppStrings.privacyPolicy,
                style: linkStyle,
                recognizer: _privacyLink,
              ),
            ],
          ),
          style: AppText.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
