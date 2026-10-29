import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/format_bytes.dart';
import '../../scan/application/cleanup_controller.dart';
import '../../scan/application/scan_controller.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/scan_models.dart';

enum NotificationGroup { today, reminders }

/// Một thông báo trong ứng dụng. Được suy ra từ trạng thái hiện tại (kết quả
/// quét, lần dọn gần nhất, dung lượng máy), không lưu riêng.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.group,
    required this.title,
    required this.body,
    required this.route,
    required this.icon,
    this.at,
    this.actionLabel,
    this.critical = false,
  });

  /// Gồm cả số liệu để khi số liệu đổi thì thông báo hiện lại là chưa đọc.
  final String id;
  final NotificationGroup group;
  final String title;
  final String body;
  final String route;
  final String icon;
  final DateTime? at;
  final String? actionLabel;
  final bool critical;
}

class ReadNotificationsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void markRead(String id) => state = {...state, id};

  void markAll(Iterable<String> ids) => state = {...state, ...ids};
}

/// Id thông báo đã đọc (trong phiên hiện tại).
final readNotificationsProvider =
    NotifierProvider<ReadNotificationsNotifier, Set<String>>(
        ReadNotificationsNotifier.new);

/// Ngưỡng coi là sắp đầy bộ nhớ.
const double kStorageWarnFraction = 0.8;

final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final scan = ref.watch(scanControllerProvider);
  final storage = ref.watch(deviceStorageProvider).valueOrNull;
  final last = ref.watch(lastCleanupProvider);
  final threshold = ref.watch(scanConfigProvider).largeVideoBytes;
  final result = scan.outcome?.result;

  final out = <AppNotification>[];

  if (last != null) {
    out.add(AppNotification(
      id: 'cleanup:${last.at.millisecondsSinceEpoch}',
      group: NotificationGroup.today,
      title: AppStrings.notifCleanupTitle,
      body: AppStrings.notifCleanupBody(last.count, formatBytes(last.bytes)),
      route: AppRoutes.notificationCleanup,
      icon: 'check',
      at: last.at,
    ));
  }

  if (result != null) {
    final groups = result.allGroups;
    if (groups.isNotEmpty) {
      final bytes = result.bytes(ScanCategory.duplicates) +
          result.bytes(ScanCategory.similar);
      out.add(AppNotification(
        id: 'duplicates:${groups.length}:$bytes',
        group: NotificationGroup.today,
        title: AppStrings.notifDuplicatesTitle(groups.length),
        body: AppStrings.notifDuplicatesBody(formatBytes(bytes)),
        route: AppRoutes.duplicates,
        icon: 'duplicates',
        actionLabel: AppStrings.viewNow,
      ));
    }
    final large = result.largeVideos;
    if (large.isNotEmpty) {
      final bytes = result.bytes(ScanCategory.largeVideos);
      out.add(AppNotification(
        id: 'large:${large.length}:$bytes',
        group: NotificationGroup.today,
        title: AppStrings.notifLargeTitle(large.length, formatBytes(threshold)),
        body: AppStrings.notifLargeBody(formatBytes(bytes)),
        route: AppRoutes.largeFiles,
        icon: 'download',
      ));
    }
  }

  if (storage != null && storage.usedFraction >= kStorageWarnFraction) {
    final percent = (storage.usedFraction * 100).round();
    out.add(AppNotification(
      id: 'storage:$percent',
      group: NotificationGroup.reminders,
      title: AppStrings.notifStorageTitle(percent),
      body: AppStrings.notifStorageBody(formatBytes(storage.freeBytes)),
      route: AppRoutes.notificationStorage,
      icon: 'warning',
      critical: true,
    ));
  }

  if (scan.outcome == null) {
    out.add(const AppNotification(
      id: 'reminder:never',
      group: NotificationGroup.reminders,
      title: AppStrings.notifReminderTitle,
      body: AppStrings.notifReminderBody,
      route: AppRoutes.notificationReminder,
      icon: 'clock',
    ));
  }

  return out;
});

/// Số thông báo chưa đọc.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final read = ref.watch(readNotificationsProvider);
  return ref
      .watch(notificationsProvider)
      .where((n) => !read.contains(n.id))
      .length;
});
