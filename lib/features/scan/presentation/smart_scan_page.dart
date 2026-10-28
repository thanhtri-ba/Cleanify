import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/secondary_button.dart';
import '../application/scan_controller.dart';
import '../application/scan_providers.dart';
import '../application/scan_routing.dart';
import '../domain/scan_models.dart';
import 'widgets/scan_labels.dart';
import 'widgets/scan_widgets.dart';

class SmartScanPage extends ConsumerStatefulWidget {
  const SmartScanPage({super.key});

  @override
  ConsumerState<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends ConsumerState<SmartScanPage> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Trường hợp mở màn khi đã xong/không có lượt quét (vd. khôi phục sau khi
    // app bị hệ thống đóng): không để người dùng kẹt ở màn tiến độ.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    final s = ref.read(scanControllerProvider);
    switch (s.phase) {
      case ScanPhase.running:
        return;
      case ScanPhase.idle:
        _leave(AppRoutes.home, replaceAll: true);
      case ScanPhase.finished:
        final route = routeForOutcome(s.outcome!);
        _leave(route, replaceAll: route == null);
    }
  }

  /// Rời màn đúng một lần. [route] null nghĩa là quay lại màn trước.
  void _leave(String? route, {bool replaceAll = false}) {
    if (_left || !mounted) return;
    _left = true;
    final router = GoRouter.of(context);
    if (route == null) {
      router.canPop() ? router.pop() : router.go(AppRoutes.home);
    } else if (replaceAll) {
      router.go(route);
    } else {
      router.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScanState>(scanControllerProvider, (prev, next) {
      if (next.phase == ScanPhase.finished &&
          prev?.phase != ScanPhase.finished) {
        _sync();
      }
    });

    final progress = ref.watch(scanControllerProvider).progress;
    final config = ref.watch(scanConfigProvider);
    final doneCount = progress.statuses.values
        .where((s) => s == CategoryStatus.done)
        .length;

    return PopScope(
      // Thoát bằng nút Stop Scan để lượt quét luôn được hủy đúng cách.
      canPop: false,
      child: PageScaffold(
        title: AppStrings.smartScan,
        showBack: false,
        stickyFooter: true,
        footer: SecondaryButton(
          label: AppStrings.stopScan,
          onPressed: () => ref.read(scanControllerProvider.notifier).cancel(),
        ),
        children: [
          Center(
            child: ProgressRing(
              progress: progress.fraction,
              size: 200,
              strokeWidth: 14,
              semanticsLabel: AppStrings.scanningTitle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${progress.percent}%', style: AppText.bigNumber),
                  Text(AppStrings.scanningStatus, style: AppText.statusLabel),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Text(
                AppStrings.scanningTitle,
                style: AppText.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.scanningSubtitle,
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          StatRow(
            stats: [
              (
                value: formatCount(progress.processedItems),
                label: AppStrings.itemsChecked,
              ),
              (
                value: '$doneCount/${ScanCategory.values.length}',
                label: AppStrings.categories,
              ),
              (
                value: formatBytes(progress.estimatedBytes),
                label: AppStrings.estimatedSpace,
              ),
            ],
          ),
          Text(AppStrings.categoriesExamined, style: AppText.sectionTitle),
          OutlinedCard(
            child: Column(
              children: withDividers([
                for (final c in ScanCategory.values)
                  CategoryRow(
                    icon: categoryIcon(c),
                    title: categoryTitle(c),
                    hint: categoryHint(c, config),
                    trailing: _status(progress.statuses[c]),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(CategoryStatus? s) {
    switch (s) {
      case CategoryStatus.done:
        return const StatusText(
          AppStrings.doneStatus,
          color: AppColors.positive,
        );
      case CategoryStatus.pending:
        return const StatusText(
          AppStrings.pendingStatus,
          color: AppColors.textMuted,
        );
      case CategoryStatus.scanning:
      case null:
        return const StatusText(AppStrings.scanningStatus);
    }
  }
}
