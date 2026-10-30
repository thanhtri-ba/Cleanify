import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import 'hero_art.dart';

/// Khung thiết kế Figma của 3 trang onboarding (px). Mọi vị trí/kích thước
/// bên dưới lấy đúng theo khung này; canvas được scale đều cho vừa màn hình
/// nên tỉ lệ giống nhau trên mọi máy.
const kDesignWidth = 393.0;
const kDesignHeight = 852.0;

/// Nền gradient + canvas cố định 393×852, scale đều (contain) và căn giữa.
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    super.key,
    required this.background,
    required this.children,
    this.onSwipeBack,
    this.onSwipeNext,
  });

  /// Vuốt từ trái sang phải: quay lại trang trước.
  final VoidCallback? onSwipeBack;

  /// Vuốt từ phải sang trái: sang trang kế tiếp.
  final VoidCallback? onSwipeNext;

  final Gradient background;

  /// Các phần tử đặt tuyệt đối trong canvas (dùng [Positioned]).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      gradient: background,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v > 300) {
            onSwipeBack?.call();
          } else if (v < -300) {
            onSwipeNext?.call();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: kDesignWidth,
                  height: kDesignHeight,
                  child: Stack(clipBehavior: Clip.none, children: children),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Duration stagger(int index) => Duration(milliseconds: 180 + index * 70);

/// Phần tử rơi vào vị trí tuyệt đối, hiện dần theo thứ tự [index].
class Rise extends StatelessWidget {
  const Rise({
    super.key,
    required this.index,
    required this.child,
    this.top,
    this.left = 0,
    this.right = 0,
    this.height,
  });

  final int index;
  final double? top;
  final double left;
  final double right;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      height: height,
      child: FadeSlideIn(delay: stagger(index), child: child),
    );
  }
}

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.top, required this.onSkip});

  final double top;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Rise(
      index: 0,
      top: top,
      left: 20,
      right: 20,
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppSvg(AppAssets.brandGlyph, width: 15, height: 18.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(AppStrings.appName, style: AppText.brand),
            ],
          ),
          Semantics(
            button: true,
            label: AppStrings.skip,
            excludeSemantics: true,
            child: Material(
              color: AppColors.skipBackground,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onSkip,
                child: SizedBox(
                  width: 80,
                  height: 28,
                  child:
                      Center(child: Text(AppStrings.skip, style: AppText.skip)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({
    super.key,
    required this.top,
    required this.text,
    required this.maxWidth,
  });

  final double top;
  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Rise(
      index: 1,
      top: top,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Semantics(
            header: true,
            child: Text(text, textAlign: TextAlign.center, style: AppText.h1),
          ),
        ),
      ),
    );
  }
}

class OnboardingBody extends StatelessWidget {
  const OnboardingBody({
    super.key,
    required this.top,
    required this.text,
    required this.sidePadding,
    this.color = AppColors.textSecondary,
  });

  final double top;
  final String text;
  final double sidePadding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Rise(
      index: 2,
      top: top,
      left: sidePadding,
      right: sidePadding,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.onboardingBody.copyWith(color: color),
      ),
    );
  }
}

/// Chấm trang; chấm đang chọn giãn từ 8 px ra [activeWidth] khi trang hiện.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    super.key,
    required this.top,
    required this.index,
    this.count = 3,
    this.activeColor = AppColors.dotActive1,
    this.activeWidth = 24,
    this.activeShadow = AppColors.dotShadowSoft,
  });

  final double top;
  final int index;
  final int count;
  final Color activeColor;
  final double activeWidth;
  final Color activeShadow;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Rise(
      index: 3,
      top: top,
      height: 8,
      child: Semantics(
        label: 'Page ${index + 1} of $count',
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                if (i == index)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 8, end: activeWidth),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, width, _) => Container(
                      width: width,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: activeShadow,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.dotInactive,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingTextAction extends StatelessWidget {
  const OnboardingTextAction({
    super.key,
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(child: Text(label, style: style)),
      ),
    );
  }
}

class OnboardingDotSeparator extends StatelessWidget {
  const OnboardingDotSeparator({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFFD1D5DB),
          shape: BoxShape.circle,
        ),
      );
}

/// Quầng sáng tím mờ phía sau hero (320×320, bán kính 226 → 0.7071, dừng ở 0.7).
class HeroGlow extends StatelessWidget {
  const HeroGlow({super.key, required this.top});

  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 36.5,
      width: 320,
      height: 320,
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              radius: 0.7071,
              colors: [AppColors.glowCenter, AppColors.glowEdge],
              stops: [0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minh hoạ động bo góc [radius], kích thước [size] (px thiết kế).
Widget _heroArt(HeroArtSpec spec, double size, double radius) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: HeroArt(spec: spec, size: size),
    );

/// Trang 1: ảnh bo 54, halo kính xoay nhẹ -1° phía sau, bóng đổ lớn.
class PhotoHero extends StatelessWidget {
  const PhotoHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 41.5,
      top: 161,
      width: 310,
      height: 310,
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        duration: const Duration(milliseconds: 800),
        dy: 20,
        scaleFrom: 0.94,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 5,
              top: 5,
              right: 5,
              bottom: 5,
              child: Transform.rotate(
                angle: -3.14159265 / 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.glass60,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: AppColors.glass60),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14111827),
                        blurRadius: 36,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(54),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F191A24),
                      blurRadius: 56,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: _heroArt(HeroArtSpec.art1, 310, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trang 2: khung kính 285 (viền 8) + huy hiệu "+4.8 GB Cleanable".
class GlassBadgeHero extends StatelessWidget {
  const GlassBadgeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 54,
      top: 146,
      width: 285,
      height: 285,
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        duration: const Duration(milliseconds: 800),
        dy: 20,
        scaleFrom: 0.94,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.glass70,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xCCFFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F111827),
                      blurRadius: 36,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14191A24),
                        blurRadius: 48,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: _heroArt(HeroArtSpec.art2, 269, 24),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -8,
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 650),
                duration: const Duration(milliseconds: 700),
                dy: 10,
                scaleFrom: 0.85,
                child: const _CleanableBadge(),
              ),
            ),
          ],
        ),
      ),
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
          Text(
            AppStrings.cleanableBadge,
            style: AppText.badge.copyWith(letterSpacing: 0.66),
          ),
        ],
      ),
    );
  }
}

/// Trang 3: vầng sáng lavender mờ (blur 40) + khung kính 280 (viền 9).
class GlassFrameHero extends StatelessWidget {
  const GlassFrameHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 63,
          top: 179,
          width: 266,
          height: 266,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
                tileMode: TileMode.decal,
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.lavenderGlow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 56.5,
          top: 172,
          width: 280,
          height: 280,
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            duration: const Duration(milliseconds: 800),
            dy: 20,
            scaleFrom: 0.94,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x99E8E7F5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 15,
                    spreadRadius: -3,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    spreadRadius: -4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _heroArt(HeroArtSpec.art3, 260, 16),
            ),
          ),
        ),
      ],
    );
  }
}
