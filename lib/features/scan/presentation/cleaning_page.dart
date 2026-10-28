import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/secondary_button.dart';
import '../application/cleanup_controller.dart';
import 'widgets/scan_widgets.dart';

class CleaningPage extends ConsumerStatefulWidget {
  const CleaningPage({super.key});

  @override
  ConsumerState<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends ConsumerState<CleaningPage> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted || _left) return;
    switch (ref.read(cleanupControllerProvider).phase) {
      case CleanupPhase.running:
        return;
      case CleanupPhase.idle:
        _left = true;
        context.go(AppRoutes.home);
      case CleanupPhase.finished:
        _left = true;
        context.pushReplacement(AppRoutes.cleanupComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CleanupState>(cleanupControllerProvider, (prev, next) {
      if (next.phase == CleanupPhase.finished &&
          prev?.phase != CleanupPhase.finished) {
        _sync();
      }
    });

    final s = ref.watch(cleanupControllerProvider);
    final processedCount = (s.fraction * s.selectedCount).round();

    return PopScope(
      // Đang xóa thì không cho thoát bằng nút Back; dùng Pause Cleanup.
      canPop: false,
      child: PageScaffold(
        title: AppStrings.cleaningStorage,
        showBack: false,
        stickyFooter: true,
        footer: SecondaryButton(
          label: s.pausing ? AppStrings.pausing : AppStrings.pauseCleanup,
          onPressed: s.pausing
              ? null
              : () => ref.read(cleanupControllerProvider.notifier).pause(),
        ),
        children: [
          Center(
            child: ProgressRing(
              progress: s.fraction,
              size: 200,
              strokeWidth: 14,
              semanticsLabel: AppStrings.cleaningProgress,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${s.percent}%', style: AppText.bigNumber),
                  Text(AppStrings.inProgress, style: AppText.statusLabel),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Text(
                AppStrings.makingRoom,
                style: AppText.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                s.fraction == 0
                    ? AppStrings.waitingConfirmation
                    : AppStrings.processingConfirmed,
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          StatRow(
            stats: [
              (
                value: formatCount(processedCount),
                label: AppStrings.mediaProcessed,
              ),
              (
                value: formatCount(s.selectedCount),
                label: AppStrings.itemsSelected,
              ),
              (
                value: formatBytes(s.remainingBytes),
                label: AppStrings.remaining,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
