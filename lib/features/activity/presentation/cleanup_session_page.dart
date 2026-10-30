import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/presentation/widgets/category_meta.dart';
import '../application/cleanup_history.dart';
import '../domain/cleanup_session.dart';
import 'activity_format.dart';
import '../../../core/theme/app_tokens.dart';

/// Session Details theo Figma 127:2133: kết quả một lần dọn dẹp đã lưu.
class CleanupSessionPage extends ConsumerWidget {
  const CleanupSessionPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(cleanupHistoryProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.activity);

    final s = _find(sessions, sessionId);
    if (s == null) {
      return SubPageScaffold(
        title: 'Session Details',
        onBack: back,
        children: [
          const SizedBox(height: 120),
          Text(
            'This session is no longer available.',
            textAlign: TextAlign.center,
            style: AppText.custom(14, FontWeight.w400, context.tokens.textSecondary,
                lineHeight: 20),
          ),
        ],
      );
    }

    return SubPageScaffold(
      title: 'Session Details',
      onBack: back,
      gap: 24,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              longDate(s.at),
              style: AppText.custom(18, FontWeight.w700, context.tokens.textPrimary,
                  lineHeight: 24),
            ),
            const SizedBox(height: 6),
            Text(
              clock(s.at),
              style: AppText.custom(13, FontWeight.w400, context.tokens.textSecondary,
                  lineHeight: 18),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Space recovered',
                    style: AppText.custom(13, FontWeight.w500,
                        context.tokens.textSecondary,
                        lineHeight: 18),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvg(AppAssets.circleCheck,
                          size: 14, color: context.tokens.textPrimary),
                      const SizedBox(width: 5),
                      Text(
                        s.completed ? 'Completed' : 'Partial',
                        style: AppText.custom(12, FontWeight.w600,
                            context.tokens.textPrimary,
                            lineHeight: 16),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                formatBytes(s.bytes),
                style: AppText.custom(36, FontWeight.w700,
                    context.tokens.textPrimary,
                    lineHeight: 42, letterSpacing: -0.8),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories processed',
              style: AppText.custom(15, FontWeight.w700, context.tokens.textPrimary,
                  lineHeight: 20),
            ),
            const SizedBox(height: 4),
            for (final c in s.categories) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: context.tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: AppSvg(c.icon,
                            size: 18, color: context.tokens.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.label,
                        style: AppText.custom(15, FontWeight.w500,
                            context.tokens.textPrimary,
                            lineHeight: 20),
                      ),
                    ),
                    AppSvg(AppAssets.check,
                        size: 17, color: context.tokens.textPrimary),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: context.tokens.border),
            ],
            if (s.categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No categories were recorded.',
                  style: AppText.custom(13, FontWeight.w400,
                      context.tokens.textSecondary,
                      lineHeight: 18),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Only the overall recovered space was recorded, not individual category sizes.',
              style: AppText.custom(12, FontWeight.w400,
                  context.tokens.textSecondary,
                  lineHeight: 18),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSvg(AppAssets.info,
                  size: 16, color: context.tokens.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'History is a record, not a backup. Deleted files can’t be restored from here.',
                  style: AppText.custom(12, FontWeight.w400,
                      context.tokens.textSecondary,
                      lineHeight: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  CleanupSession? _find(List<CleanupSession> list, int id) {
    for (final s in list) {
      if (s.id == id) return s;
    }
    return null;
  }
}
