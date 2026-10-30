import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/tab_scaffold.dart';
import '../../scan/presentation/scan_actions.dart';
import '../application/cleanup_history.dart';
import '../domain/cleanup_session.dart';
import 'activity_format.dart';
import '../../../core/theme/app_tokens.dart';

enum _Range { thisMonth, allTime }

/// Tab Activity theo Figma 127:1984: tổng dung lượng đã dọn, biểu đồ tuần
/// và các lần dọn gần đây.
class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  _Range _range = _Range.thisMonth;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(cleanupHistoryProvider);
    final now = DateTime.now();
    final inRange = _range == _Range.allTime
        ? sessions
        : [
            for (final s in sessions)
              if (s.at.year == now.year && s.at.month == now.month) s,
          ];
    final total = inRange.fold<int>(0, (a, s) => a + s.bytes);
    final bottom =
        math.max(20.0, MediaQuery.viewPaddingOf(context).bottom + 16);

    return TabScaffold(
      current: AppTab.activity,
      onScan: () => startScanFlow(context, ref),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottom),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity',
                      style: AppText.custom(28, FontWeight.w700,
                          context.tokens.textPrimary,
                          lineHeight: 34, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your cleanup history',
                      style: AppText.custom(
                          14, FontWeight.w400, context.tokens.textSecondary,
                          lineHeight: 20),
                    ),
                  ],
                ),
                _RangeFilter(
                  value: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              label: _range == _Range.allTime
                  ? 'Recovered all time'
                  : 'Recovered this month',
              total: total,
              week: weeklyBytes(sessions, now),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cleanup history',
                  style: AppText.custom(18, FontWeight.w700,
                      context.tokens.textPrimary,
                      lineHeight: 24),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(AppRoutes.cleanupHistory),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'See all',
                      style: AppText.custom(
                          13, FontWeight.w600, context.tokens.textPrimary,
                          lineHeight: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RecentCard(sessions: sessions.take(3).toList(), now: now),
          ],
        ),
      ),
    );
  }
}

/// Bộ lọc khoảng thời gian: This Month / All Time.
class _RangeFilter extends StatelessWidget {
  const _RangeFilter({required this.value, required this.onChanged});

  final _Range value;
  final ValueChanged<_Range> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Range>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: _Range.thisMonth, child: Text('This Month')),
        PopupMenuItem(value: _Range.allTime, child: Text('All Time')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.tokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == _Range.thisMonth ? 'This Month' : 'All Time',
              style: AppText.custom(13, FontWeight.w600, context.tokens.textPrimary,
                  lineHeight: 18),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: context.tokens.textPrimary),
          ],
        ),
      ),
    );
  }
}

/// Thẻ tổng dung lượng kèm biểu đồ 7 cột theo ngày trong tuần.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.total,
    required this.week,
  });

  final String label;
  final int total;
  final List<int> week;

  @override
  Widget build(BuildContext context) {
    final maxDay = week.reduce((a, b) => a > b ? a : b);
    final highlight = maxDay > 0 ? week.indexOf(maxDay) : -1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.tokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A202020),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.custom(13, FontWeight.w600, context.tokens.textSecondary,
                lineHeight: 18),
          ),
          const SizedBox(height: 4),
          Text(
            formatBytes(total),
            style: AppText.custom(32, FontWeight.w700, context.tokens.textPrimary,
                lineHeight: 38, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: maxDay == 0 ? 6 : 6 + 48 * week[i] / maxDay,
                          decoration: BoxDecoration(
                            color: i == highlight
                                ? const Color(0xFF555555)
                                : context.tokens.iconTile,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekdayShort[i],
                          style: AppText.custom(
                              11, FontWeight.w400, context.tokens.textSecondary,
                              lineHeight: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ba lần dọn gần nhất; bấm vào để xem chi tiết.
class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.sessions, required this.now});

  final List<CleanupSession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.tokens.border),
        ),
        child: Text(
          'No cleanups yet. Finished cleanups will appear here.',
          style: AppText.custom(13, FontWeight.w400, context.tokens.textSecondary,
              lineHeight: 18),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sessions.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.tokens.border),
            _SessionRow(
              session: sessions[i],
              now: now,
              onTap: () =>
                  context.push(AppRoutes.cleanupSessionPath(sessions[i].id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.now,
    required this.onTap,
  });

  final CleanupSession session;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                dayChip(session.at, now),
                style: AppText.custom(12, FontWeight.w700,
                    context.tokens.textPrimary,
                    lineHeight: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatBytes(session.bytes)} recovered',
                    style: AppText.custom(15, FontWeight.w600,
                        context.tokens.textPrimary,
                        lineHeight: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoriesLine(session.categories),
                    style: AppText.custom(13, FontWeight.w400,
                        context.tokens.textSecondary,
                        lineHeight: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatBytes(session.bytes),
                  style: AppText.custom(14, FontWeight.w700,
                      context.tokens.textPrimary,
                      lineHeight: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  clock(session.at),
                  style: AppText.custom(12, FontWeight.w400,
                      context.tokens.textSecondary,
                      lineHeight: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
