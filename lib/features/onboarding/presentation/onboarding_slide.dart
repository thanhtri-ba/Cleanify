import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';

enum HeroStyle { photo, glassWithBadge, glassFrame }

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.heroStyle,
    required this.heroSize,
  });

  final String title;
  final String description;
  final String imageAsset;
  final HeroStyle heroStyle;

  /// Kích thước hero theo Figma (px); sẽ co lại nếu màn hình thấp.
  final double heroSize;
}

const onboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    title: AppStrings.onboarding1Title,
    description: AppStrings.onboarding1Body,
    imageAsset: AppAssets.onboarding1,
    heroStyle: HeroStyle.photo,
    heroSize: 310,
  ),
  OnboardingSlide(
    title: AppStrings.onboarding2Title,
    description: AppStrings.onboarding2Body,
    imageAsset: AppAssets.onboarding2,
    heroStyle: HeroStyle.glassWithBadge,
    heroSize: 285,
  ),
  OnboardingSlide(
    title: AppStrings.onboarding3Title,
    description: AppStrings.onboarding3Body,
    imageAsset: AppAssets.onboarding3,
    heroStyle: HeroStyle.glassFrame,
    heroSize: 280,
  ),
];
