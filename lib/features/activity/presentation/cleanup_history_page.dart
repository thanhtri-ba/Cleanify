import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_svg.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../../scan/presentation/scan_actions.dart';
import '../application/cleanup_history.dart';
import '../domain/cleanup_session.dart';
import 'activity_format.dart';
import '../../../core/theme/app_tokens.dart';

/// Cleanup History theo Figma 127:2076. Khi chưa có lần dọn nào hiển thị
/// trạng thái rỗng theo 127:2191.
class CleanupHistoryPage extends ConsumerWidget {
  const CleanupHistoryPage({super.key});

  static const _title = 'Cleanup History';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(cleanupHistoryProvider);
    void back() => context.canPop() ? context.pop() : context.go(AppRoutes.activity);

    if (sessions.isEmpty) {
      return SubPageScaffold(
        title: _title,
        onBack: back,
        children: [
          _EmptyHistory(onStart: () => startScanFlow(context, ref)),
        ],
      );
    }

    final now = DateTime.now();
    final groups = <String, List<CleanupSession>>{};
    for (final s in sessions) {
      groups.putIfAbsent(monthYear(s.at), () => []).add(s);
    }

    return SubPageScaffold(
      title: _title,
      onBack: back,
      gap: 20,
      children: [
        for (final e in groups.entries)
          _MonthSection(
            title: e.key,
            sessions: e.value,
            now: now,
            onOpen: (s) => context.push(AppRoutes.cleanupSessionPath(s.id)),
          ),
        Text(
          'Select a session to view its recorded results.',
          style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary,
              lineHeight: 18),
        ),
      ],
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.title,
    required this.sessions,
    required this.now,
    required this.onOpen,
  });

  final String title;
  final List<CleanupSession> sessions;
  final DateTime now;
  final ValueChanged<CleanupSession> onOpen;

  @override
  Widget build(BuildContext context) {
    final count = sessions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppText.custom(18, FontWeight.w700, context.tokens.textPrimary,
                  lineHeight: 24),
            ),
            Text(
              '$count ${count == 1 ? 'session' : 'sessions'}',
              style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary,
                  lineHeight: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, thickness: 1, color: context.tokens.border),
        for (final s in sessions)
          _HistoryEntry(session: s, onTap: () => onOpen(s)),
      ],
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.session, required this.onTap});

  final CleanupSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shortDate(session.at),
                          style: AppText.custom(15, FontWeight.w600,
                              context.tokens.textPrimary,
                              lineHeight: 20),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          clock(session.at),
                          style: AppText.custom(13, FontWeight.w400,
                              context.tokens.textSecondary,
                              lineHeight: 18),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatBytes(session.bytes),
                            style: AppText.custom(18, FontWeight.w700,
                                context.tokens.textPrimary,
                                lineHeight: 22),
                          ),
                          Text(
                            'recovered',
                            style: AppText.custom(12, FontWeight.w400,
                                context.tokens.textSecondary,
                                lineHeight: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppSvg(AppAssets.chevronRight,
                        size: 16, color: context.tokens.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  categoriesLine(session.categories),
                  style: AppText.custom(13, FontWeight.w400,
                      context.tokens.textSecondary,
                      lineHeight: 19),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.tokens.border),
        ],
      ),
    );
  }
}

/// Trạng thái chưa có lần dọn nào, kèm nút bắt đầu quét.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 120),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: AppSvg(AppAssets.history,
                size: 36, color: context.tokens.textPrimary),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No cleanups yet',
          textAlign: TextAlign.center,
          style: AppText.custom(22, FontWeight.w700, context.tokens.textPrimary,
              lineHeight: 28),
        ),
        const SizedBox(height: 10),
        Text(
          'After your first cleanup, completed sessions and their results will appear here.',
          textAlign: TextAlign.center,
          style: AppText.custom(14, FontWeight.w400, context.tokens.textSecondary,
              lineHeight: 21),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 49,
          child: Material(
            color: const Color(0xFF434343),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onStart,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppSvg(AppAssets.scanLine,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Start Cleanup',
                    style: AppText.custom(14, FontWeight.w600, Colors.white,
                        lineHeight: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Review what to remove before you confirm.',
          textAlign: TextAlign.center,
          style: AppText.custom(12, FontWeight.w400, context.tokens.textSecondary,
              lineHeight: 18),
        ),
      ],
    );
  }
}
