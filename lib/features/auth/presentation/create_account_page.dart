import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/create_account_controller.dart';
import '../application/social_sign_in_controller.dart';
import 'auth_messages.dart';
import 'widgets/auth_widgets.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(createAccountControllerProvider.notifier).submit(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
  }

  void _goToSignIn() {
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
    final controller = ref.read(createAccountControllerProvider.notifier);

    ref.listen<CreateAccountState>(createAccountControllerProvider,
        (previous, next) {
      if (next.completed && !(previous?.completed ?? false)) {
        context.go(AppRoutes.verifyEmail);
      }
    });

    final failure = state.failure ?? social.failure;
    final failureMessage = failure == null ? null : authFailureMessage(failure);
    final busy = state.isSubmitting || social.inProgress != null;

    return AuthScaffold(
      title: AppStrings.createTitle,
      subtitle: AppStrings.createSubtitle,
      onBack: _goToSignIn,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: AppStrings.fullNameLabel,
              hint: AppStrings.fullNameHint,
              leadingIcon: AppAssets.userRound,
              controller: _name,
              enabled: !state.isSubmitting,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              errorText: state.nameError == null
                  ? null
                  : fieldErrorMessage(state.nameError!),
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: AppStrings.emailLabel,
              hint: AppStrings.emailHint,
              leadingIcon: AppAssets.mail,
              controller: _email,
              focusNode: _emailFocus,
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
            const SizedBox(height: 12),
            AppTextField(
              label: AppStrings.passwordLabel,
              hint: AppStrings.passwordHintCreate,
              leadingIcon: AppAssets.lockKeyhole,
              controller: _password,
              focusNode: _passwordFocus,
              enabled: !state.isSubmitting,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              // Khi có lỗi, thông báo lỗi chính là quy tắc mật khẩu nên ẩn
              // dòng gợi ý bên dưới để không lặp lại cùng một câu.
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
            if (state.passwordError == null) ...[
              const SizedBox(height: 12),
              Text(AppStrings.passwordRule, style: AppText.caption),
            ],
            const SizedBox(height: 12),
            // Chưa có màn Terms / Privacy nên hai liên kết này chưa bấm được.
            Text.rich(
              TextSpan(
                style: AppText.captionSecondary,
                children: [
                  const TextSpan(text: AppStrings.termsPrefix),
                  TextSpan(text: AppStrings.termsOfService, style: _linkStyle),
                  const TextSpan(text: AppStrings.termsMiddle),
                  TextSpan(text: AppStrings.privacyPolicy, style: _linkStyle),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (failureMessage != null) ...[
              FormErrorBanner(message: failureMessage),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: AppStrings.createButton,
              isLoading: state.isSubmitting,
              onPressed: busy ? null : _submit,
            ),
          ],
        ),
        SocialSignInSection(enabled: !state.isSubmitting),
        AuthSwitchPrompt(
          prompt: AppStrings.alreadyHaveAccount,
          action: AppStrings.signInLink,
          onTap: busy ? null : _goToSignIn,
        ),
      ],
    );
  }

  static final TextStyle _linkStyle = AppText.captionSecondary.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.underline,
  );
}
