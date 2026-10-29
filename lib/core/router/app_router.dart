import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/presentation/storage_analysis_page.dart';
import '../../features/app_manager/presentation/app_manager_page.dart';
import '../../features/duplicates/presentation/duplicate_photos_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/large_files/presentation/large_files_page.dart';
import '../../features/notifications/presentation/cleanup_detail_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/notifications/presentation/scan_reminder_page.dart';
import '../../features/notifications/presentation/storage_warning_page.dart';
import '../../features/library/presentation/photo_library_page.dart';
import '../../features/onboarding/presentation/onboarding_step1_page.dart';
import '../../features/onboarding/presentation/onboarding_step2_page.dart';
import '../../features/onboarding/presentation/onboarding_step3_page.dart';
import '../../features/permissions/presentation/file_access_page.dart';
import '../../features/scan/presentation/cleaning_page.dart';
import '../../features/scan/presentation/cleanup_complete_page.dart';
import '../../features/scan/presentation/review_cleanup_page.dart';
import '../../features/scan/presentation/scan_complete_page.dart';
import '../../features/scan/presentation/scan_empty_page.dart';
import '../../features/scan/presentation/scan_error_page.dart';
import '../../features/scan/presentation/scan_partial_page.dart';
import '../../features/scan/presentation/smart_scan_page.dart';
import 'app_routes.dart';

/// Onboarding, xin quyền, Home và luồng quét → xem lại → dọn dẹp.
/// Trang 2 và 3 lồng dưới trang 1 để nút back hệ thống quay về đúng trang.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingStep1Page(),
        routes: [
          GoRoute(
            path: '2',
            builder: (context, state) => const OnboardingStep2Page(),
          ),
          GoRoute(
            path: '3',
            builder: (context, state) => const OnboardingStep3Page(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const SmartScanPage(),
      ),
      GoRoute(
        path: AppRoutes.scanComplete,
        builder: (context, state) => const ScanCompletePage(),
      ),
      GoRoute(
        path: AppRoutes.scanEmpty,
        builder: (context, state) => const ScanEmptyPage(),
      ),
      GoRoute(
        path: AppRoutes.scanPartial,
        builder: (context, state) => const ScanPartialPage(),
      ),
      GoRoute(
        path: AppRoutes.scanError,
        builder: (context, state) => const ScanErrorPage(),
      ),
      GoRoute(
        path: AppRoutes.cleanupReview,
        builder: (context, state) => const ReviewCleanupPage(),
      ),
      GoRoute(
        path: AppRoutes.cleanupProgress,
        builder: (context, state) => const CleaningPage(),
      ),
      GoRoute(
        path: AppRoutes.cleanupComplete,
        builder: (context, state) => const CleanupCompletePage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationCleanup,
        builder: (context, state) => const CleanupDetailPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationStorage,
        builder: (context, state) => const StorageWarningPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationReminder,
        builder: (context, state) => const ScanReminderPage(),
      ),
      GoRoute(
        path: AppRoutes.duplicates,
        builder: (context, state) => const DuplicatePhotosPage(),
      ),
      GoRoute(
        path: AppRoutes.largeFiles,
        builder: (context, state) => const LargeFilesPage(),
      ),
      GoRoute(
        path: AppRoutes.photoLibrary,
        builder: (context, state) => const PhotoLibraryPage(),
      ),
      GoRoute(
        path: AppRoutes.appManager,
        builder: (context, state) => const AppManagerPage(),
      ),
      GoRoute(
        path: AppRoutes.storageAnalysis,
        builder: (context, state) => const StorageAnalysisPage(),
      ),
      GoRoute(
        path: AppRoutes.fileAccess,
        builder: (context, state) => const FileAccessPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
