import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/onboarding_state.dart';
import 'onboarding_hero.dart';
import 'onboarding_slide.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _index = 0;

  int get _last => onboardingSlides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page.clamp(0, _last),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Đánh dấu đã xem onboarding rồi chuyển tới [route]. Lấy router trước khi
  /// await vì lúc này redirect có thể đã gỡ trang hiện tại khỏi cây widget.
  Future<void> _finish(String route) async {
    final router = GoRouter.of(context);
    await ref.read(onboardingSeenProvider.notifier).complete();
    router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _OnboardingHeader(onSkip: () => _finish(AppRoutes.signIn)),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingSlides.length,
                  onPageChanged: (page) => setState(() => _index = page),
                  itemBuilder: (context, page) =>
                      _SlideContent(slide: onboardingSlides[page]),
                ),
              ),
              _Footer(
                index: _index,
                onNext: () => _goTo(_index + 1),
                onPrevious: () => _goTo(_index - 1),
                onHaveAccount: () => _finish(AppRoutes.signIn),
                onStartTrial: () => _finish(AppRoutes.createAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
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
                    child:
                        AppSvg(AppAssets.brandGlyph, width: 15, height: 18.3),
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
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onSkip,
                  child: SizedBox(
                    width: 80,
                    height: 28,
                    child: Center(
                      child: Text(AppStrings.skip, style: AppText.skip),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Hero co lại theo không gian còn lại để không tràn trên máy thấp.
              final available = math.max(
                0.0,
                math.min(constraints.maxWidth - 40, constraints.maxHeight - 24),
              );
              return Center(
                child: OnboardingHero(
                  slide: slide,
                  size: math.min(slide.heroSize, available),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Semantics(
            header: true,
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: AppText.h1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: AppText.onboardingBody,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.index,
    required this.onNext,
    required this.onPrevious,
    required this.onHaveAccount,
    required this.onStartTrial,
  });

  final int index;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onHaveAccount;
  final VoidCallback onStartTrial;

  @override
  Widget build(BuildContext context) {
    const arrow = AppSvg(AppAssets.arrowRight, size: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageDots(count: onboardingSlides.length, index: index),
          const SizedBox(height: 24),
          switch (index) {
            0 => PrimaryButton(
                label: AppStrings.getStarted,
                height: 58,
                labelStyle: AppText.ctaLabel,
                prominentShadow: true,
                onPressed: onNext,
              ),
            1 => PrimaryButton(
                label: AppStrings.continueLabel,
                height: 56,
                labelStyle: AppText.ctaLabel.copyWith(fontSize: 16),
                trailing: arrow,
                prominentShadow: true,
                onPressed: onNext,
              ),
            _ => PrimaryButton(
                label: AppStrings.startFreeTrial,
                height: 56,
                labelStyle: AppText.ctaLabel,
                trailing: arrow,
                prominentShadow: true,
                onPressed: onStartTrial,
              ),
          },
          const SizedBox(height: 12),
          switch (index) {
            0 => _TextAction(
                label: AppStrings.haveAccount,
                style: AppText.subtleLink,
                onTap: onHaveAccount,
              ),
            1 => _TextAction(
                label: AppStrings.back,
                style: AppText.skip,
                onTap: onPrevious,
              ),
            // Chưa làm in-app purchase / màn Terms nên hai mục này chưa bấm được.
            _ => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      AppStrings.restorePurchases,
                      style: AppText.subtleLink,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const _Dot(),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Text(
                      AppStrings.termsAndPrivacy,
                      style: AppText.subtleLink,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          },
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFFC7C4D7),
          shape: BoxShape.circle,
        ),
      );
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.primary : AppColors.dotInactive,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
