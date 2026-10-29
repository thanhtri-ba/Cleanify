import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_assets.dart';
import '../../domain/scan_models.dart';

/// Tên, icon và mô tả của từng danh mục dùng chung cho các màn quét/dọn dẹp.
extension ScanCategoryUi on ScanCategory {
  String get label => switch (this) {
        ScanCategory.duplicates => AppStrings.duplicatePhotos,
        ScanCategory.similar => AppStrings.similarPhotos,
        ScanCategory.largeVideos => AppStrings.largeVideos,
        ScanCategory.screenshots => AppStrings.screenshots,
      };

  String get icon => switch (this) {
        ScanCategory.duplicates => AppAssets.fileText,
        ScanCategory.similar => AppAssets.image,
        ScanCategory.largeVideos => AppAssets.clapperboard,
        ScanCategory.screenshots => AppAssets.download,
      };

  /// Mô tả ngắn khi liệt kê kết quả. [count] là số mục xóa được,
  /// [threshold] là ngưỡng video lớn đã định dạng (vd. "150 MB").
  String resultHint(int count, String threshold) => switch (this) {
        ScanCategory.duplicates => AppStrings.identicalShots(count),
        ScanCategory.similar => AppStrings.hintSimilarResult,
        ScanCategory.largeVideos => AppStrings.hintVideos(threshold),
        ScanCategory.screenshots => AppStrings.hintScreenshotsResult,
      };

  /// Mô tả khi danh mục đang được quét.
  String scanningHint(String threshold) => switch (this) {
        ScanCategory.duplicates => AppStrings.hintDuplicatesScanning,
        ScanCategory.similar => AppStrings.hintSimilarScanning,
        ScanCategory.largeVideos => AppStrings.hintVideos(threshold),
        ScanCategory.screenshots => AppStrings.hintScreenshotsScanning,
      };
}
