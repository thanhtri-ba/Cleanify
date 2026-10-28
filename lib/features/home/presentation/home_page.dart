import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/device_storage.dart';
import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../scan/presentation/widgets/media_thumbnail.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Dùng trong test để nhận biết đã vào Home.
  static const pageKey = Key('home-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(deviceStorageProvider);
    final scan = ref.watch(scanControllerProvider);
    final scanning = scan.phase == ScanPhase.running;

    return Scaffold(
      key: pageKey,
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            _StorageCard(
              storage: storage,
              onRetry: () => ref.invalidate(deviceStorageProvider),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: AppStrings.scanPhotosVideos,
              leading: const AppSvg(
                AppAssets.sparkles,
                size: 18,
                color: Colors.white,
              ),
              prominentShadow: true,
              onPressed: () {
                // Đang quét thì đưa người dùng về màn tiến độ thay vì quét lại.
                if (scanning) {
                  context.push(AppRoutes.scan);
                } else {
                  startScanFlow(context, ref);
                }
              },
            ),
            const SizedBox(height: 16),
            _DuplicatesCard(result: scan.outcome?.result),
            const SizedBox(height: 16),
            const _FeatureCard(
              icon: AppAssets.clapperboard,
              title: AppStrings.largeVideos,
              action: AppStrings.inspect,
            ),
            const SizedBox(height: 12),
            const _FeatureCard(
              icon: AppAssets.layers,
              title: AppStrings.appManager,
              action: AppStrings.reviewApps,
            ),
            const SizedBox(height: 12),
            const _FeatureCard(
              icon: AppAssets.database,
              title: AppStrings.storageAnalysis,
              action: AppStrings.storageOverview,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppSvg(AppAssets.brandMark, size: 32),
        const SizedBox(width: 10),
        Text('Cleanify', style: AppText.brand),
      ],
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.storage, required this.onRetry});

  final AsyncValue<DeviceStorage> storage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppStrings.systemCapacity, style: AppText.sectionTitle),
          ),
          const SizedBox(height: 16),
          storage.when(
            data: (s) => _Data(s),
            loading: () => const _Ring(fraction: 0, label: '—'),
            error: (_, __) => Column(
              children: [
                const _Ring(fraction: 0, label: '—'),
                const SizedBox(height: 12),
                Text(
                  AppStrings.storageUnavailable,
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(AppStrings.retry, style: AppText.linkAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Data extends StatelessWidget {
  const _Data(this.storage);

  final DeviceStorage storage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Ring(
          fraction: storage.usedFraction,
          label: '${(storage.usedFraction * 100).round()}%',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Legend(
                color: AppColors.primary,
                label: AppStrings.legendUsed,
                value: formatBytes(storage.usedBytes),
              ),
            ),
            Expanded(
              child: _Legend(
                color: AppColors.segmentOff,
                label: AppStrings.legendFree,
                value: formatBytes(storage.freeBytes),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.fraction, required this.label});

  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ProgressRing(
      progress: fraction,
      size: 160,
      strokeWidth: 14,
      semanticsLabel: AppStrings.systemCapacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.display),
          Text(AppStrings.used, style: AppText.statLabel),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.statLabel),
            Text(value, style: AppText.rowTitle),
          ],
        ),
      ],
    );
  }
}

class _DuplicatesCard extends StatelessWidget {
  const _DuplicatesCard({required this.result});

  /// null khi chưa quét lần nào.
  final ScanResult? result;

  @override
  Widget build(BuildContext context) {
    final groups = result?.allGroups ?? const <MediaGroup>[];
    final hasGroups = groups.isNotEmpty;

    final Widget body;
    if (result == null) {
      body = Text(AppStrings.noScanYet, style: AppText.caption);
    } else if (!hasGroups) {
      body = Text(AppStrings.noDuplicatesFound, style: AppText.caption);
    } else {
      final first = groups.first.items.take(3).toList();
      body = Row(
        children: [
          for (final item in first) ...[
            MediaThumbnail(id: item.id, size: 72),
            const SizedBox(width: 8),
          ],
          if (groups.length > 1)
            Text(
              AppStrings.moreSets(groups.length - 1),
              style: AppText.statusLabel,
            ),
        ],
      );
    }

    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.duplicatePhotos, style: AppText.rowTitle),
              ),
              if (hasGroups)
                TextButton(
                  onPressed: () => context.push(AppRoutes.scanComplete),
                  child: Text(AppStrings.review, style: AppText.linkAccent),
                ),
            ],
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

/// Thẻ tính năng chưa có màn đích (sẽ nối ở các lô sau): hiển thị mờ,
/// không bấm được, để không có nút "chết".
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.action,
  });

  final String icon;
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: OutlinedCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.categoryTile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: AppSvg(icon, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.rowTitle),
                  Text(AppStrings.comingSoon, style: AppText.rowHint),
                ],
              ),
            ),
            Text(action, style: AppText.statusLabel),
          ],
        ),
      ),
    );
  }
}
