import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/email_masking.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../application/pending_verification.dart';
import '../application/verify_email_controller.dart';
import 'auth_parts.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(verifyEmailControllerProvider.notifier).reset();
    });
  }

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.signIn);
    }
  }

  void _changeEmail() {
    ref.read(pendingVerificationEmailProvider.notifier).clear();
    context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(pendingVerificationEmailProvider);
    final state = ref.watch(verifyEmailControllerProvider);
    final canResend = state.canResend && email != null;

    return AuthScaffold(
      title: AppStrings.verifyTitle,
      subtitle: AppStrings.verifySubtitle,
      onBack: _backToSignIn,
      children: [
        const Center(child: _VerificationHero()),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warnTint,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              AppStrings.verificationPending,
              style: AppText.custom(12, FontWeight.w600, AppColors.warnText),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(AppStrings.yourEmailAddress, style: AppText.fieldLabel),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderNeutral),
          ),
          child: Row(
            children: [
              const AppSvg(
                AppAssets.mail,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  email == null ? '' : maskEmail(email),
                  style: AppText.input,
                ),
              ),
              TextButton(
                onPressed: _changeEmail,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(AppStrings.changeEmail, style: AppText.link),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(AppStrings.verifyInstruction, style: AppText.body),
        AuthErrorBanner(message: authFailureMessage(state.failure)),
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
                child: Text(AppStrings.verifyNote, style: AppText.noteBody),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: state.cooldownSeconds > 0
              ? AppStrings.resendIn(state.cooldownSeconds)
              : AppStrings.resendVerification,
          height: 56,
          radius: 18,
          color: Colors.black,
          labelStyle: AppText.permPrimary,
          shadows: const [],
          isLoading: state.isSending,
          onPressed: canResend
              ? () => ref.read(verifyEmailControllerProvider.notifier).resend()
              : null,
        ),
        if (state.justSent) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSvg(
                AppAssets.circleCheck,
                size: 15,
                color: AppColors.positive,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  AppStrings.verificationSent,
                  style: AppText.captionSecondary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SecondaryButton(
          label: AppStrings.backToSignInButton,
          height: 56,
          radius: 18,
          labelStyle: AppText.permSecondary,
          onPressed: _backToSignIn,
        ),
      ],
    );
  }
}

class _VerificationHero extends StatelessWidget {
  const _VerificationHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: const Center(
        child: AppSvg(
          AppAssets.mailCheck,
          size: 32,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
