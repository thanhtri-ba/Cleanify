import '../../../core/router/app_routes.dart';
import '../domain/scan_models.dart';

/// Màn cần mở khi lượt quét kết thúc. null nghĩa là quay lại màn trước
/// (người dùng đã tự dừng quét).
String? routeForOutcome(ScanOutcome outcome) {
  switch (outcome.end) {
    case ScanEnd.cancelled:
      return null;
    case ScanEnd.completed:
      return outcome.result.isEmpty
          ? AppRoutes.scanEmpty
          : AppRoutes.scanComplete;
    case ScanEnd.interrupted:
      return outcome.hasResults ? AppRoutes.scanPartial : AppRoutes.scanError;
  }
}
