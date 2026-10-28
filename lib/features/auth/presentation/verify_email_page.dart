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
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../application/pending_verification.dart';
import '../application/verify_email_controller.dart';
import 'auth_messages.dart';

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
      if (!mounted) return;
      ref.read(verifyEmailControllerProvider.notifier).reset();
    });
  }

  void _backToSignIn() {
    ref.read(pendingVerificationEmailProvider.notifier).clear();
    context.go(AppRoutes.signIn);
  }

  void _changeEmail() {
    ref.read(pendingVerificationEmailProvider.notifier).clear();
    context.go(AppRoutes.createAccount);
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(pendingVerificationEmailProvider);
    final state = ref.watch(verifyEmailControllerProvider);
    final failureMessage =
        state.failure == null ? null : authFailureMessage(state.failure!);

    final resendLabel = state.cooldownSeconds > 0
        ? '${AppStrings.resendVerification} (${state.cooldownSeconds}s)'
        : AppStrings.resendVerification;

    return AuthScaffold(
      title: AppStrings.verifyTitle,
      subtitle: AppStrings.verifySubtitle,
      onBack: _backToSignIn,
      footer: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: resendLabel,
              isLoading: state.isSending,
              onPressed: state.canResend
                  ? () =>
                      ref.read(verifyEmailControllerProvider.notifier).resend()
                  : null,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: AppStrings.backToSignInButton,
              onPressed: _backToSignIn,
            ),
          ],
        ),
      ),
      children: [
        const _PendingIllustration(),
        _DetailsCard(
          maskedEmail: maskEmail(email ?? ''),
          onChangeEmail: _changeEmail,
        ),
        if (failureMessage != null)
          FormErrorBanner(message: failureMessage)
        else if (state.justSent)
          const InfoBanner(message: AppStrings.verificationSent)
        else
          const InfoBanner(message: AppStrings.verifyNote),
      ],
    );
  }
}

class _PendingIllustration extends StatelessWidget {
  const _PendingIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x17625BEE),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.iconTile,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: AppSvg(AppAssets.mailCheck, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.verificationPending,
            style: AppText.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.maskedEmail, required this.onChangeEmail});

  final String maskedEmail;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.yourEmailAddress,
            style: AppText.caption,
          ),
          const SizedBox(height: 12),
          Text(
            maskedEmail,
            style: AppText.h1.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.verifyInstruction,
            textAlign: TextAlign.center,
            style: AppText.bodySmall,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onChangeEmail,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(AppStrings.changeEmail, style: AppText.link),
            ),
          ),
        ],
      ),
    );
  }
}
