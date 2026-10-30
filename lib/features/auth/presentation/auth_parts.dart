import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_svg.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';

String fieldErrorMessage(FieldError? error) => switch (error) {
      null => '',
      FieldError.emailRequired => AppStrings.errEmailRequired,
      FieldError.emailInvalid => AppStrings.errEmailInvalid,
      FieldError.passwordRequired => AppStrings.errPasswordRequired,
      FieldError.passwordWeak => AppStrings.passwordRule,
      FieldError.nameRequired => AppStrings.errNameRequired,
      FieldError.nameTooLong => AppStrings.errNameTooLong,
    };

String authFailureMessage(AuthFailure? failure) => switch (failure) {
      null => '',
      InvalidCredentials() => AppStrings.errInvalidCredentials,
      EmailAlreadyInUse() => AppStrings.errEmailInUse,
      EmailNotVerified() => AppStrings.errEmailNotVerified,
      WeakPassword() => AppStrings.passwordRule,
      NetworkFailure() => AppStrings.errNetwork,
      TooManyRequests() => AppStrings.errTooManyRequests,
      UserCancelled() => '',
      UnknownAuthFailure() => AppStrings.errUnknown,
    };

/// Khung chung cho 4 màn tài khoản: nút back, tiêu đề, nội dung cuộn.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (onBack != null)
                      Semantics(
                        button: true,
                        label: AppStrings.back,
                        excludeSemantics: true,
                        child: Material(
                          color: AppColors.surface,
                          shape: const CircleBorder(
                            side: BorderSide(color: AppColors.borderNeutral),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onBack,
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: AppSvg(
                                  AppAssets.chevronLeft,
                                  size: 18,
                                  color: AppColors.titleInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: AppText.custom(
                          28, FontWeight.w700, AppColors.titleInk,
                          lineHeight: 34, letterSpacing: -0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppText.body),
                    const SizedBox(height: 24),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    super.key,
    required this.onSelected,
    this.enabled = true,
  });

  final ValueChanged<SocialProvider> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(AppStrings.orContinueWith, style: AppText.caption),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 16),
        AuthSocialButton(
          icon: AppAssets.googleLogo,
          label: AppStrings.continueWithGoogle,
          onPressed: enabled ? () => onSelected(SocialProvider.google) : null,
        ),
        const SizedBox(height: 10),
        AuthSocialButton(
          icon: AppAssets.appleLogo,
          iconColor: AppColors.textPrimary,
          label: AppStrings.signInWithApple,
          onPressed: enabled ? () => onSelected(SocialProvider.apple) : null,
        ),
      ],
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.label,
    required this.onTap,
  });

  final String prompt;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppText.bodySmall),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(label, style: AppText.link),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.helper,
    this.error,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.fieldLabel),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.borderNeutral,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: AppSvg(
                    prefixIcon!,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  autofillHints: autofillHints,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: AppText.input,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: hint,
                    hintStyle: AppText.hint,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: prefixIcon == null ? 14 : 10,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (onToggleObscure != null)
                Semantics(
                  button: true,
                  label: obscure
                      ? AppStrings.showPassword
                      : AppStrings.hidePassword,
                  excludeSemantics: true,
                  child: IconButton(
                    onPressed: onToggleObscure,
                    icon: AppSvg(
                      AppAssets.eye,
                      size: 18,
                      color: obscure ? AppColors.textMuted : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!, style: AppText.error),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(helper!, style: AppText.caption),
          ),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSvg(AppAssets.warning, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppText.error.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  final String icon;
  final Color? iconColor;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderNeutral),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvg(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.social,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
