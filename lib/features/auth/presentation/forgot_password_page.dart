import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/forgot_password_controller.dart';
import 'auth_parts.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(forgotPasswordControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(email: _email.text);
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
    final state = ref.watch(forgotPasswordControllerProvider);

    return AuthScaffold(
      title: AppStrings.forgotTitle,
      subtitle: AppStrings.forgotSubtitle,
      onBack: context.canPop() ? () => context.pop() : null,
      children: [
        if (state.sent) ...[
          const _SentPanel(),
          const SizedBox(height: 24),
          PrimaryButton(
            label: AppStrings.backToSignInButton,
            height: 56,
            radius: 18,
            color: Colors.black,
            labelStyle: AppText.permPrimary,
            shadows: const [],
            onPressed: _backToSignIn,
          ),
        ] else ...[
          AuthTextField(
            label: AppStrings.emailLabel,
            controller: _email,
            hint: AppStrings.emailHint,
            prefixIcon: AppAssets.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            error: fieldErrorMessage(state.emailError),
            onChanged: (_) => ref
                .read(forgotPasswordControllerProvider.notifier)
                .clearErrors(),
            onSubmitted: (_) => _submit(),
          ),
          AuthErrorBanner(message: authFailureMessage(state.failure)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: AppStrings.sendResetLink,
            height: 56,
            radius: 18,
            color: Colors.black,
            labelStyle: AppText.permPrimary,
            shadows: const [],
            isLoading: state.isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderNeutral),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSvg(
                  AppAssets.info,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppStrings.forgotNote, style: AppText.noteBody),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AuthFooterLink(
            prompt: '',
            label: AppStrings.backToSignInLink,
            onTap: _backToSignIn,
          ),
        ],
      ],
    );
  }
}

class _SentPanel extends StatelessWidget {
  const _SentPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: AppSvg(
                AppAssets.mailCheck,
                size: 26,
                color: AppColors.positive,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.resetSent,
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
