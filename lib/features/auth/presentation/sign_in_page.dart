import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/sign_in_controller.dart';
import '../application/social_sign_in_controller.dart';
import 'auth_messages.dart';
import 'widgets/auth_widgets.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Bắt đầu màn với trạng thái sạch (controller sống lâu hơn trang).
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
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(signInControllerProvider.notifier).submit(
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final social = ref.watch(socialSignInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);

    ref.listen<SignInState>(signInControllerProvider, (previous, next) {
      final becameUnverified =
          next.needsVerification && !(previous?.needsVerification ?? false);
      if (becameUnverified) context.go(AppRoutes.verifyEmail);
    });

    final failure = state.failure ?? social.failure;
    final failureMessage = failure == null ? null : authFailureMessage(failure);
    final busy = state.isSubmitting || social.inProgress != null;

    return AuthScaffold(
      title: AppStrings.signInTitle,
      subtitle: AppStrings.signInSubtitle,
      // Sign in là màn gốc sau onboarding nên thường không có gì để quay lại.
      onBack: context.canPop() ? () => context.pop() : null,
      footer: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSvg(AppAssets.shieldCheck, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child:
                  Text(AppStrings.privacyReassurance, style: AppText.caption),
            ),
          ],
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: AppStrings.emailLabel,
              hint: AppStrings.emailHint,
              leadingIcon: AppAssets.mail,
              controller: _email,
              enabled: !state.isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              errorText: state.emailError == null
                  ? null
                  : fieldErrorMessage(state.emailError!),
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppStrings.passwordLabel,
              hint: AppStrings.passwordHintSignIn,
              leadingIcon: AppAssets.lockKeyhole,
              controller: _password,
              focusNode: _passwordFocus,
              enabled: !state.isSubmitting,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              errorText: state.passwordError == null
                  ? null
                  : fieldErrorMessage(state.passwordError!),
              trailing: PasswordVisibilityToggle(
                obscured: _obscure,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap:
                    busy ? null : () => context.push(AppRoutes.forgotPassword),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child:
                      Text(AppStrings.forgotPasswordLink, style: AppText.link),
                ),
              ),
            ),
            if (failureMessage != null) ...[
              FormErrorBanner(message: failureMessage),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: AppStrings.signInButton,
              isLoading: state.isSubmitting,
              onPressed: busy ? null : _submit,
            ),
          ],
        ),
        SocialSignInSection(enabled: !state.isSubmitting),
        AuthSwitchPrompt(
          prompt: AppStrings.newToCleanify,
          action: AppStrings.createAccountLink,
          onTap: busy ? null : () => context.push(AppRoutes.createAccount),
        ),
      ],
    );
  }
}
