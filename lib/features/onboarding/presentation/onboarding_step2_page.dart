import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import 'onboarding_parts.dart';

/// Trang 2: "Find & Remove Similar Photos".
class OnboardingStep2Page extends StatelessWidget {
  const OnboardingStep2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      background: AppColors.onboarding2Gradient,
      onSwipeBack: () {
        if (context.canPop()) context.pop();
      },
      onSwipeNext: () => context.push(AppRoutes.onboarding3),
      children: [
        const HeroGlow(top: 122),
        const GlassBadgeHero(),
        OnboardingHeader(
          top: 20,
          onSkip: () => context.go(AppRoutes.onboarding3),
        ),
        const OnboardingTitle(
          top: 504,
          text: AppStrings.onboarding2Title,
          maxWidth: 296,
        ),
        const OnboardingBody(
          top: 577,
          text: AppStrings.onboarding2Body,
          sidePadding: 54,
        ),
        const OnboardingDots(
          top: 686,
          index: 1,
          activeColor: AppColors.dotActive2,
        ),
        Rise(
          index: 4,
          top: 718,
          left: 20,
          right: 20,
          child: PrimaryButton(
            label: AppStrings.continueLabel,
            height: 56,
            color: context.tokens.cta,
            labelStyle: AppText.ctaLarge,
            trailing: const AppSvg(AppAssets.arrowRight, size: 12),
            prominentShadow: true,
            onPressed: () => context.push(AppRoutes.onboarding3),
          ),
        ),
        Rise(
          index: 5,
          top: 786,
          left: 28,
          right: 33,
          child: SecondaryButton(
            label: AppStrings.back,
            height: 54,
            borderColor: context.tokens.border,
            labelStyle: AppText.skip,
            // Bóng hơi đỏ này đúng theo Figma.
            shadows: const [
              BoxShadow(
                color: Color(0x40B04545),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
