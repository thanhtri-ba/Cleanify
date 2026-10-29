import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../permissions/application/media_access_controller.dart';
import '../../permissions/domain/media_access.dart';
import '../application/scan_controller.dart';

/// Bắt đầu một lượt quét từ Home. Nếu chưa có quyền ảnh thì mở màn xin quyền
/// thay vì quét (quét khi không có quyền chỉ cho kết quả rỗng gây hiểu nhầm).
Future<void> startScanFlow(BuildContext context, WidgetRef ref) async {
  await ref.read(mediaAccessProvider.notifier).refresh();
  if (!context.mounted) return;

  final granted = ref.read(mediaAccessProvider).access;
  if (granted != MediaAccess.granted && granted != MediaAccess.limited) {
    context.push(AppRoutes.fileAccess);
    return;
  }
  // start() đặt trạng thái "đang quét" ngay (đồng bộ), nên Smart Scan mở ra
  // đã thấy tiến độ thay vì trạng thái cũ.
  ref.read(scanControllerProvider.notifier).start();
  context.push(AppRoutes.scan);
}

/// Quét lại từ màn kết quả/lỗi: thay màn hiện tại bằng Smart Scan.
void restartScan(BuildContext context, WidgetRef ref) {
  ref.read(scanControllerProvider.notifier).start();
  context.pushReplacement(AppRoutes.scan);
}
