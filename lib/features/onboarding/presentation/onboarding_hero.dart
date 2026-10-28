import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'onboarding_slide.dart';

/// Ảnh minh họa của từng slide. Nền kính mờ trong Figma được xấp xỉ bằng màu
/// trong suốt (chưa dùng BackdropFilter vì nền phía sau là gradient phẳng).
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({super.key, required this.slide, required this.size});

  final OnboardingSlide slide;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (slide.heroStyle) {
      HeroStyle.photo => _PhotoHero(asset: slide.imageAsset, size: size),
      HeroStyle.glassWithBadge =>
        _GlassBadgeHero(asset: slide.imageAsset, size: size),
      HeroStyle.glassFrame =>
        _GlassFrameHero(asset: slide.imageAsset, size: size),
    };
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: AppColors.primaryTint),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.glowCenter, AppColors.glowEdge],
          stops: [0, 0.7],
        ),
      ),
    );
  }
}

class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(54);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _Glow(diameter: size * 320 / 310),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F191A24),
                blurRadius: 56,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(borderRadius: radius, child: _HeroImage(asset)),
        ),
      ],
    );
  }
}

class _GlassBadgeHero extends StatelessWidget {
  const _GlassBadgeHero({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _Glow(diameter: size * 320 / 285),
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.glass70,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.glass80),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F625BEE),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _HeroImage(asset),
          ),
        ),
        const Positioned(right: -4, bottom: -8, child: _CleanableBadge()),
      ],
    );
  }
}

class _CleanableBadge extends StatelessWidget {
  const _CleanableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.glass90,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.glassBorder30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14191A24),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(AppStrings.cleanableBadge, style: AppText.badge),
        ],
      ),
    );
  }
}

class _GlassFrameHero extends StatelessWidget {
  const _GlassFrameHero({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size - 14,
          height: size - 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lavenderGlow,
            boxShadow: [
              BoxShadow(color: AppColors.lavenderGlow, blurRadius: 40),
            ],
          ),
        ),
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.glass80,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _HeroImage(asset),
          ),
        ),
      ],
    );
  }
}
