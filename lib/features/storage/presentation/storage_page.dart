import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/primary_button.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/device_storage.dart';
import '../../scan/presentation/scan_actions.dart';

/// Tab Storage: dung lượng máy và các mục có thể dọn.
class StoragePage extends ConsumerWidget {
  const StoragePage({super.key});

  static const pageKey = Key('storage-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(deviceStorageProvider);
    final scan = ref.watch(scanControllerProvider);
    final result = scan.outcome?.result;
    final threshold = ref.watch(scanConfigProvider).largeVideoBytes;
    final scanning = scan.phase == ScanPhase.running;
    final bottom =
        math.max(24.0, MediaQuery.viewPaddingOf(context).bottom + 16);

    return Scaffold(
      key: pageKey,
      backgroundColor: context.tokens.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                  color: context.tokens.surfaceMuted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 16, color: context.tokens.textPrimary),
                    ),
                  ),
                ),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.navStorage, style: AppText.h1),
            const SizedBox(height: 4),
            Text(AppStrings.storageTabBody, style: AppText.captionSecondary),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: storage.when(
                data: (s) => _CapacityCard(storage: s),
                loading: () => const _CapacityCard(),
                error: (_, __) => _StorageErrorCard(
                  onRetry: () => ref.invalidate(deviceStorageProvider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: AppStrings.scanForJunk,
              height: 54,
              radius: 9999,
              isLoading: scanning,
              gradient: AppColors.ctaGradient,
              onPressed: scanning ? null : () => startScanFlow(context, ref),
              leading: AppSvg(
                AppAssets.scanTarget,
                size: 18,
                color: context.tokens.surface,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.freeUpSpace,
              style: AppText.custom(15, FontWeight.w700, context.tokens.textPrimary),
            ),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _TileGroup(
                children: [
                  _StorageTile(
                    icon: AppAssets.image,
                    title: AppStrings.duplicatePhotos,
                    subtitle: result == null
                        ? AppStrings.noScanYetShort
                        : AppStrings.groupsReclaimable(result.allGroups.length),
                    onTap: () => context.push(AppRoutes.duplicates),
                  ),
                  _StorageTile(
                    icon: AppAssets.download,
                    title: AppStrings.largeFiles,
                    subtitle: result == null
                        ? AppStrings.hintVideos(formatBytes(threshold))
                        : AppStrings.largeVideosCount(
                            result.largeVideos.length),
                    onTap: () => context.push(AppRoutes.largeFiles),
                  ),
                  _StorageTile(
                    icon: AppAssets.folder,
                    title: AppStrings.photoLibrary,
                    subtitle: AppStrings.photoLibrarySubtitle,
                    onTap: () => context.push(AppRoutes.photoLibrary),
                  ),
                  _StorageTile(
                    icon: AppAssets.gridDots,
                    title: AppStrings.appManager,
                    subtitle: AppStrings.appManagerCaption,
                    onTap: () => context.push(AppRoutes.appManager),
                  ),
                  _StorageTile(
                    icon: AppAssets.barChart,
                    title: AppStrings.storageAnalysis,
                    subtitle: AppStrings.storageOverview,
                    onTap: () => context.push(AppRoutes.storageAnalysis),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({this.storage});

  /// null khi đang tải.
  final DeviceStorage? storage;

  @override
  Widget build(BuildContext context) {
    final s = storage;
    final used = s == null ? null : splitBytes(s.usedBytes);
    final fraction = (s?.usedFraction ?? 0).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final muted = AppText.custom(11, FontWeight.w600, AppColors.onHeroMuted,
        lineHeight: 14);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.heroBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E111827),
            blurRadius: 32,
            spreadRadius: -12,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.onHero,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(AppStrings.capacity, style: muted),
              const Spacer(),
              Text(
                s == null ? '' : '$percent% ${AppStrings.used.toLowerCase()}',
                style: muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  used?.value ?? '—',
                  style: AppText.custom(44, FontWeight.w700, AppColors.onHero,
                      lineHeight: 48, letterSpacing: -1.1),
                ),
                const SizedBox(width: 8),
                Text(
                  used?.unit ?? 'GB',
                  style: AppText.custom(
                      18, FontWeight.w600, AppColors.onHeroSecondary,
                      lineHeight: 24, letterSpacing: -0.3),
                ),
                if (s != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '/ ${formatBytes(s.totalBytes)}',
                    style: AppText.custom(
                        13, FontWeight.w400, AppColors.onHeroFaint,
                        lineHeight: 20),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.heroTrack),
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF7FA8FF),
                                  context.tokens.surface,
                                ],
                              ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const _LegendDot(color: AppColors.onHero),
              const SizedBox(width: 6),
              Text(AppStrings.legendUsed, style: muted),
              const SizedBox(width: 8),
              Text(
                s == null ? '—' : formatBytes(s.usedBytes),
                style: AppText.custom(14, FontWeight.w600, AppColors.onHero,
                    lineHeight: 20),
              ),
              const Spacer(),
              const _LegendDot(color: AppColors.heroSegmentFree),
              const SizedBox(width: 6),
              Text(AppStrings.legendFree, style: muted),
              const SizedBox(width: 8),
              Text(
                s == null ? '—' : formatBytes(s.freeBytes),
                style: AppText.custom(14, FontWeight.w600, AppColors.onHero,
                    lineHeight: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageErrorCard extends StatelessWidget {
  const _StorageErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.storageUnavailable,
            style: AppText.custom(14, FontWeight.w500, context.tokens.textSecondary,
                lineHeight: 20),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(AppStrings.retry, style: AppText.linkAccent),
          ),
        ],
      ),
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 64,
                color: context.tokens.divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _StorageTile extends StatelessWidget {
  const _StorageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.tokens.iconTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: AppSvg(icon, size: 18, color: AppColors.accentDeep),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.rowTitle),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowHint,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppSvg(
                AppAssets.chevronRight,
                size: 14,
                color: context.tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
