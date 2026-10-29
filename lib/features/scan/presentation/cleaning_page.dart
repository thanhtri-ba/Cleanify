import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../application/cleanup_controller.dart';
import 'widgets/flow_parts.dart';

/// Cleaning: tiến độ xóa thật; xong thì sang Cleanup Complete, bị từ chối/lỗi
/// thì về Review để người dùng quyết định.
class CleaningPage extends ConsumerStatefulWidget {
  const CleaningPage({super.key});

  @override
  ConsumerState<CleaningPage> createState() => _CleaningPageState();
}

class _CleaningPageState extends ConsumerState<CleaningPage> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handle(ref.read(cleanupControllerProvider));
    });
  }

  void _handle(CleanupState s) {
    if (_handled || s.phase != CleanupPhase.finished) return;
    final o = s.outcome;
    if (o == null) return;
    _handled = true;
    if (o.declined) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text(AppStrings.deletionNotConfirmed)));
      context.pushReplacement(AppRoutes.cleanupReview);
    } else {
      context.pushReplacement(AppRoutes.cleanupComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CleanupState>(cleanupControllerProvider, (_, n) => _handle(n));
    final s = ref.watch(cleanupControllerProvider);
    final waiting = s.fraction == 0 && s.phase == CleanupPhase.running;

    return PopScope(
      canPop: false,
      child: FlowScaffold(
        title: AppStrings.cleaningStorage,
        bottom: FlowActionBar(
          children: [
            FlowSecondaryButton(
              label: s.pausing ? AppStrings.pausing : AppStrings.pauseCleanup,
              onPressed: s.pausing || s.phase != CleanupPhase.running
                  ? null
                  : () => ref.read(cleanupControllerProvider.notifier).pause(),
            ),
          ],
        ),
        children: staggered([
          Column(
            children: [
              Text(
                AppStrings.makingRoom,
                textAlign: TextAlign.center,
                style: AppText.custom(22, FontWeight.w600, AppColors.titleInk,
                    lineHeight: 28, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(
                waiting
                    ? AppStrings.waitingConfirmation
                    : AppStrings.processingConfirmed,
                textAlign: TextAlign.center,
                style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                    lineHeight: 20),
              ),
            ],
          ),
          GroupCard(
            color: AppColors.iconTile,
            bordered: false,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.cleaningProgress,
                          style: AppText.custom(
                              12, FontWeight.w500, AppColors.textMuted,
                              lineHeight: 16),
                        ),
                        Text(
                          AppStrings.inProgress,
                          style: AppText.custom(
                              11, FontWeight.w600, AppColors.primary,
                              lineHeight: 14, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.percent}%',
                      style: AppText.custom(
                          40, FontWeight.w700, AppColors.primary,
                          lineHeight: 46, letterSpacing: -1),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: s.fraction.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: AppColors.surface,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GroupCard(
            children: [
              _stat(AppStrings.mediaProcessed, formatBytes(s.processedBytes)),
              _stat(AppStrings.itemsSelected, formatCount(s.selectedCount)),
              _stat(AppStrings.remaining, formatBytes(s.remainingBytes)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppText.custom(14, FontWeight.w400, AppColors.textBody,
                    lineHeight: 20)),
            RowValue(value),
          ],
        ),
      );
}
