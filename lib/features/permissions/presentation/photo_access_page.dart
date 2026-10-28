import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/state_panel.dart';
import '../application/media_access_controller.dart';
import '../domain/media_access.dart';

/// Một route, ba giao diện theo trạng thái quyền: intro / limited / denied.
class PhotoAccessPage extends ConsumerStatefulWidget {
  const PhotoAccessPage({super.key});

  @override
  ConsumerState<PhotoAccessPage> createState() => _PhotoAccessPageState();
}

class _PhotoAccessPageState extends ConsumerState<PhotoAccessPage>
    with WidgetsBindingObserver {
  bool _finishing = false;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialRefresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Người dùng có thể vừa đổi quyền trong Settings rồi quay lại.
    if (state == AppLifecycleState.resumed) {
      ref.read(mediaAccessProvider.notifier).refresh();
    }
  }

  Future<void> _initialRefresh() async {
    if (!mounted) return;
    await ref.read(mediaAccessProvider.notifier).refresh();
    if (!mounted) return;
    if (ref.read(mediaAccessProvider).access == MediaAccess.granted) {
      _finish();
    }
  }

  /// Ghi nhận đã qua màn này rồi vào Home. Chỉ chạy một lần.
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final router = GoRouter.of(context);
    try {
      await ref.read(photoAccessPromptSeenProvider.notifier).markSeen();
    } catch (_) {
      // Không lưu được cờ vẫn cho người dùng đi tiếp.
    }
    router.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MediaAccessState>(mediaAccessProvider, (previous, next) {
      if (next.access == MediaAccess.granted) _finish();
    });

    final state = ref.watch(mediaAccessProvider);
    final notifier = ref.read(mediaAccessProvider.notifier);
    final view = resolvePhotoAccessView(
      state.access,
      hasRequested: state.hasRequested,
      isIos: _isIos,
    );

    switch (view) {
      case PhotoAccessView.granted:
        // Đang chuyển sang Home.
        return const Scaffold(body: SizedBox.shrink());
      case PhotoAccessView.intro:
        return _IntroView(
          isIos: _isIos,
          isRequesting: state.isRequesting,
          onContinue: notifier.request,
          onNotNow: _finish,
        );
      case PhotoAccessView.limited:
        return _LimitedView(
          onManage: notifier.manageLimited,
          onContinue: _finish,
        );
      case PhotoAccessView.denied:
        return _DeniedView(
          isIos: _isIos,
          onOpenSettings: notifier.openSettings,
          onContinue: _finish,
        );
    }
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h1),
        const SizedBox(height: 8),
        Text(body, style: AppText.body),
      ],
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.isIos,
    required this.isRequesting,
    required this.onContinue,
    required this.onNotNow,
  });

  final bool isIos;
  final bool isRequesting;
  final VoidCallback onContinue;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppStrings.photoAccessTitle,
      children: const [
        _Intro(
          title: AppStrings.accessIntroTitle,
          body: AppStrings.accessIntroBody,
        ),
        StatePanel(icon: AppAssets.images),
        _Benefits(),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isIos ? AppStrings.accessNextIos : AppStrings.accessNextAndroid,
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: AppStrings.continueLabel,
            isLoading: isRequesting,
            onPressed: onContinue,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: AppStrings.notNow,
            onPressed: isRequesting ? null : onNotNow,
          ),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoRow(
          icon: AppAssets.scanLine,
          title: AppStrings.accessBenefit1Title,
          body: AppStrings.accessBenefit1Body,
        ),
        SizedBox(height: 20),
        InfoRow(
          icon: AppAssets.shieldCheck,
          title: AppStrings.accessBenefit2Title,
          body: AppStrings.accessBenefit2Body,
        ),
        SizedBox(height: 20),
        InfoRow(
          icon: AppAssets.circleCheck,
          title: AppStrings.accessBenefit3Title,
          body: AppStrings.accessBenefit3Body,
        ),
      ],
    );
  }
}

class _LimitedView extends StatelessWidget {
  const _LimitedView({required this.onManage, required this.onContinue});

  final VoidCallback onManage;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppStrings.photoAccessTitle,
      children: [
        const _Intro(
          title: AppStrings.limitedTitle,
          body: AppStrings.limitedBody,
        ),
        const StatePanel(
          icon: AppAssets.images,
          caption: AppStrings.limitedCaption,
        ),
        OutlinedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      AppStrings.photoAccessTitle,
                      style: AppText.rowTitle,
                    ),
                  ),
                  const _Badge(label: AppStrings.limitedBadge),
                ],
              ),
              const SizedBox(height: 16),
              const InfoRow(
                icon: AppAssets.images,
                title: AppStrings.limitedScopeTitle,
                body: AppStrings.limitedScopeBody,
              ),
            ],
          ),
        ),
        const InfoBanner(message: AppStrings.limitedNote),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: AppStrings.manageSelectedMedia,
            leading: const AppSvg(AppAssets.plus, size: 18),
            onPressed: onManage,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: AppStrings.continueWithSelected,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _DeniedView extends StatelessWidget {
  const _DeniedView({
    required this.isIos,
    required this.onOpenSettings,
    required this.onContinue,
  });

  final bool isIos;
  final VoidCallback onOpenSettings;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppStrings.photoAccessTitle,
      children: [
        const _Intro(
          title: AppStrings.deniedTitle,
          body: AppStrings.deniedBody,
        ),
        const StatePanel(
          icon: AppAssets.imageOff,
          caption: AppStrings.deniedCaption,
        ),
        OutlinedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoRow(
                icon: AppAssets.images,
                title: AppStrings.deniedUnavailableTitle,
                body: AppStrings.deniedUnavailableBody,
              ),
              const SizedBox(height: 18),
              _HowTo(isIos: isIos),
            ],
          ),
        ),
        const InfoBanner(message: AppStrings.deniedNote),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: AppStrings.openSettings,
            leading: const AppSvg(AppAssets.settings, size: 18),
            onPressed: onOpenSettings,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: AppStrings.continueWithoutAccess,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo({required this.isIos});

  final bool isIos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIos
                ? AppStrings.deniedHowToTitleIos
                : AppStrings.deniedHowToTitleAndroid,
            style: AppText.rowTitle.copyWith(fontSize: 12, height: null),
          ),
          const SizedBox(height: 4),
          Text(
            isIos ? AppStrings.deniedHowToIos : AppStrings.deniedHowToAndroid,
            style: AppText.captionSecondary,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.iconTile,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppText.statusLabel.copyWith(fontSize: 11, height: null),
      ),
    );
  }
}
