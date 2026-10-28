import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_svg.dart';
import '../../application/social_sign_in_controller.dart';
import '../../domain/auth_user.dart';

/// Nút hiện/ẩn mật khẩu. Figma chỉ có icon "eye" (đang ẩn); icon "đang hiện"
/// tạm dùng Material icon vì chưa có trong thiết kế.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onPressed,
  });

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: obscured ? AppStrings.showPassword : AppStrings.hidePassword,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: obscured
                ? const AppSvg(AppAssets.eye, size: 20)
                : const Icon(
                    Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Dòng "Already have an account? Sign in" / "New to Cleanify? Create account".
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(prompt, style: AppText.bodySmall)),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(action, style: AppText.link),
          ),
        ),
      ],
    );
  }
}

/// Đường kẻ "or continue with" + 3 nút đăng nhập mạng xã hội.
class SocialSignInSection extends ConsumerWidget {
  const SocialSignInSection({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialSignInControllerProvider);
    final busy = state.inProgress != null;
    void signIn(SocialProvider provider) =>
        ref.read(socialSignInControllerProvider.notifier).signIn(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _Rule()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(AppStrings.orContinueWith, style: AppText.caption),
            ),
            const Expanded(child: _Rule()),
          ],
        ),
        const SizedBox(height: 20),
        _SocialButton(
          label: AppStrings.continueWithGoogle,
          background: AppColors.surface,
          border: AppColors.borderNeutral,
          foreground: AppColors.textPrimary,
          leading: const AppSvg(AppAssets.googleLogo, size: 20),
          loading: state.inProgress == SocialProvider.google,
          onPressed:
              enabled && !busy ? () => signIn(SocialProvider.google) : null,
        ),
        const SizedBox(height: 10),
        _SocialButton(
          label: AppStrings.signInWithApple,
          background: AppColors.black,
          foreground: Colors.white,
          leading: const AppSvg(AppAssets.appleLogo, width: 18, height: 22),
          loading: state.inProgress == SocialProvider.apple,
          onPressed:
              enabled && !busy ? () => signIn(SocialProvider.apple) : null,
        ),
        const SizedBox(height: 10),
        _SocialButton(
          label: AppStrings.continueWithFacebook,
          background: AppColors.facebook,
          foreground: Colors.white,
          leading: const Text(
            'f',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          loading: state.inProgress == SocialProvider.facebook,
          onPressed:
              enabled && !busy ? () => signIn(SocialProvider.facebook) : null,
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: AppColors.border));
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.leading,
    required this.onPressed,
    required this.loading,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget leading;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !loading ? 0.6 : 1,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: border == null ? BorderSide.none : BorderSide(color: border!),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox(
              height: 48,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: AppText.social.copyWith(color: foreground),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
