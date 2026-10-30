import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import 'onboarding_parts.dart';

/// Trang 1: "A Cleaner Phone Starts Here".
class OnboardingStep1Page extends StatelessWidget {
  const OnboardingStep1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      background: AppColors.onboarding1Gradient,
      onSwipeNext: () => context.push(AppRoutes.onboarding2),
      children: [
        const HeroGlow(top: 118),
        const PhotoHero(),
        OnboardingHeader(
          top: 16,
          onSkip: () => context.go(AppRoutes.onboarding3),
        ),
        const OnboardingTitle(
          top: 499,
          text: AppStrings.onboarding1Title,
          maxWidth: 296,
        ),
        OnboardingBody(
          top: 572,
          text: AppStrings.onboarding1Body,
          sidePadding: 56,
          color: context.tokens.textSecondary,
        ),
        const OnboardingDots(top: 682, index: 0),
        Rise(
          index: 4,
          top: 714,
          left: 20,
          right: 20,
          child: PrimaryButton(
            label: AppStrings.getStarted,
            height: 58,
            color: context.tokens.cta,
            labelStyle: AppText.ctaLabel,
            prominentShadow: true,
            onPressed: () => context.push(AppRoutes.onboarding2),
          ),
        ),
      ],
    );
  }
}
