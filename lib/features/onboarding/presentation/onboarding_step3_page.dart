import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/onboarding_state.dart';
import 'onboarding_parts.dart';

/// Trang 3: "Smart Protection & Private Vault".
class OnboardingStep3Page extends ConsumerWidget {
  const OnboardingStep3Page({super.key});

  static const _linkColor = Color(0xCC464555); // #464555 ở 80%

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkStyle = AppText.subtleLink.copyWith(color: _linkColor);
    return OnboardingFrame(
      background: AppColors.onboarding3Gradient,
      onSwipeBack: () {
        if (context.canPop()) context.pop();
      },
      children: [
        const GlassFrameHero(),
        // Đang ở trang cuối nên Skip không cần làm gì.
        OnboardingHeader(top: 20, onSkip: () {}),
        const OnboardingTitle(
          top: 500,
          text: AppStrings.onboarding3Title,
          maxWidth: 330,
        ),
        OnboardingBody(
          top: 571,
          text: AppStrings.onboarding3Body,
          sidePadding: 36,
          color: context.tokens.textSecondary,
        ),
        const OnboardingDots(
          top: 686,
          index: 2,
          activeColor: Colors.black,
          activeWidth: 28,
          activeShadow: AppColors.dotShadowViolet,
        ),
        Rise(
          index: 4,
          top: 718,
          left: 20,
          right: 20,
          child: PrimaryButton(
            label: AppStrings.startFreeTrial,
            height: 56,
            color: context.tokens.cta,
            labelStyle: AppText.ctaLabel,
            trailing: const AppSvg(AppAssets.arrowRight, size: 13.33),
            shadows: const [
              BoxShadow(
                color: Color(0x4D111827),
                blurRadius: 15,
                spreadRadius: -3,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x4D111827),
                blurRadius: 6,
                spreadRadius: -4,
                offset: Offset(0, 4),
              ),
            ],
            onPressed: () async {
              await ref.read(onboardingSeenProvider.notifier).complete();
              if (context.mounted) context.go(AppRoutes.fileAccess);
            },
          ),
        ),
        // Chưa làm in-app purchase / màn Terms nên hai mục này chưa bấm được.
        Rise(
          index: 5,
          top: 792,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppStrings.restorePurchases, style: linkStyle),
              const SizedBox(width: 20),
              const OnboardingDotSeparator(),
              const SizedBox(width: 20),
              Text(AppStrings.termsAndPrivacy, style: linkStyle),
            ],
          ),
        ),
      ],
    );
  }
}
