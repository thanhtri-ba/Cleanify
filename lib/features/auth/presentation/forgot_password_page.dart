import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/forgot_password_controller.dart';
import 'auth_messages.dart';

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
      if (!mounted) return;
      ref.read(forgotPasswordControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
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
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    final failureMessage =
        state.failure == null ? null : authFailureMessage(state.failure!);

    return AuthScaffold(
      title: AppStrings.forgotTitle,
      subtitle: AppStrings.forgotSubtitle,
      onBack: _backToSignIn,
      footer: SizedBox(
        height: 40,
        child: Center(
          child: InkWell(
            onTap: _backToSignIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Text(AppStrings.backToSignInLink, style: AppText.link),
            ),
          ),
        ),
      ),
      children: [
        const _StateIllustration(icon: AppAssets.keyRound),
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              errorText: state.emailError == null
                  ? null
                  : fieldErrorMessage(state.emailError!),
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            if (failureMessage != null) ...[
              FormErrorBanner(message: failureMessage),
              const SizedBox(height: 12),
            ],
            if (state.sent) ...[
              const InfoBanner(message: AppStrings.resetSent),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: AppStrings.sendResetLink,
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ],
        ),
        const InfoBanner(message: AppStrings.forgotNote),
      ],
    );
  }
}

class _StateIllustration extends StatelessWidget {
  const _StateIllustration({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Center(
        child: Container(
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
              child: Center(child: AppSvg(icon, size: 28)),
            ),
          ),
        ),
      ),
    );
  }
}
