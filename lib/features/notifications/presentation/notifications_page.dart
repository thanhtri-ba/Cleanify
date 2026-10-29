import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/sub_page_scaffold.dart';
import '../application/notifications_providers.dart';

/// Thông báo: danh sách suy ra từ trạng thái thật của ứng dụng.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static const _icons = {
    'check': AppAssets.check,
    'duplicates': AppAssets.image,
    'download': AppAssets.download,
    'warning': AppAssets.warning,
    'clock': AppAssets.info,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    final read = ref.watch(readNotificationsProvider);
    final hasUnread = items.any((n) => !read.contains(n.id));

    void open(AppNotification n) {
      ref.read(readNotificationsProvider.notifier).markRead(n.id);
      context.push(n.route);
    }

    Widget tile(AppNotification n) => _NotificationTile(
          item: n,
          unread: !read.contains(n.id),
          asset: _icons[n.icon] ?? AppAssets.bell,
          onTap: () => open(n),
        );

    final today =
        items.where((n) => n.group == NotificationGroup.today).toList();
    final reminders =
        items.where((n) => n.group == NotificationGroup.reminders).toList();

    return SubPageScaffold(
      title: AppStrings.notifTitle,
      onBack: () => context.pop(),
      action: hasUnread
          ? SubPill(
              label: AppStrings.notifMarkAllRead,
              onTap: () => ref
                  .read(readNotificationsProvider.notifier)
                  .markAll(items.map((n) => n.id)),
            )
          : null,
      children: [
        if (items.isEmpty)
          const SubEmpty(
            asset: AppAssets.bell,
            title: AppStrings.notifEmptyTitle,
            body: AppStrings.notifEmptyBody,
          ),
        if (today.isNotEmpty) const SubSectionLabel(AppStrings.notifToday),
        for (final n in today) tile(n),
        if (reminders.isNotEmpty)
          const SubSectionLabel(AppStrings.notifReminders),
        for (final n in reminders) tile(n),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.unread,
    required this.asset,
    required this.onTap,
  });

  final AppNotification item;
  final bool unread;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = item.at == null ? null : agoLabel(item.at!);
    return SubCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubIconTile(
            asset: asset,
            color: item.critical ? AppColors.error : AppColors.titleInk,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppText.custom(
                    14,
                    unread ? FontWeight.w600 : FontWeight.w500,
                    unread ? AppColors.titleInk : AppColors.textSecondary,
                    lineHeight: 19,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: AppText.custom(
                      12.5, FontWeight.w400, AppColors.textMuted,
                      lineHeight: 17),
                ),
                if (item.actionLabel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      item.actionLabel!,
                      style: AppText.custom(12, FontWeight.w600, Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (time != null)
                Text(
                  time,
                  style: AppText.custom(11, FontWeight.w400, AppColors.textMuted),
                ),
              if (unread) ...[
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
