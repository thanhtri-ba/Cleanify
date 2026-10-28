import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../domain/scan_models.dart';

String categoryTitle(ScanCategory c) {
  switch (c) {
    case ScanCategory.duplicates:
      return AppStrings.duplicatePhotos;
    case ScanCategory.similar:
      return AppStrings.similarPhotos;
    case ScanCategory.largeVideos:
      return AppStrings.largeVideos;
    case ScanCategory.screenshots:
      return AppStrings.screenshots;
  }
}

String categoryHint(ScanCategory c, ScanConfig config) {
  switch (c) {
    case ScanCategory.duplicates:
      return AppStrings.hintDuplicatesScanning;
    case ScanCategory.similar:
      return AppStrings.hintSimilarScanning;
    case ScanCategory.largeVideos:
      return AppStrings.hintVideos(formatBytes(config.largeVideoBytes));
    case ScanCategory.screenshots:
      return AppStrings.hintScreenshotsScanning;
  }
}

String categoryIcon(ScanCategory c) {
  switch (c) {
    case ScanCategory.duplicates:
      return AppAssets.layers;
    case ScanCategory.similar:
      return AppAssets.images;
    case ScanCategory.largeVideos:
      return AppAssets.clapperboard;
    case ScanCategory.screenshots:
      return AppAssets.image;
  }
}
