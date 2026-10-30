import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/activity_page.dart';
import '../../features/support/presentation/help_feedback_page.dart';
import '../../features/activity/presentation/cleanup_history_page.dart';
import '../../features/activity/presentation/cleanup_session_page.dart';
import '../../features/analysis/presentation/storage_analysis_page.dart';
import '../../features/app_manager/presentation/app_manager_page.dart';
import '../../features/permissions/presentation/photo_denied_page.dart';
import '../../features/permissions/presentation/photo_limited_page.dart';
import '../../features/duplicates/presentation/duplicate_photos_page.dart';
import '../../features/duplicates/presentation/group_review_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/large_files/presentation/large_files_page.dart';
import '../../features/notifications/presentation/cleanup_detail_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/notifications/presentation/scan_reminder_page.dart';
import '../../features/notifications/presentation/storage_warning_page.dart';
import '../../features/library/presentation/photo_library_page.dart';
import '../../features/onboarding/application/onboarding_state.dart';
import '../../features/onboarding/presentation/onboarding_step1_page.dart';
import '../../features/onboarding/presentation/onboarding_step2_page.dart';
import '../../features/onboarding/presentation/onboarding_step3_page.dart';
import '../../features/permissions/application/media_access_controller.dart';
import '../../features/permissions/presentation/file_access_page.dart';
import '../../features/scan/presentation/cleaning_page.dart';
import '../../features/scan/presentation/cleanup_complete_page.dart';
import '../../features/scan/presentation/review_cleanup_page.dart';
import '../../features/scan/presentation/scan_complete_page.dart';
import '../../features/scan/presentation/scan_empty_page.dart';
import '../../features/scan/presentation/scan_error_page.dart';
import '../../features/scan/presentation/scan_partial_page.dart';
import '../../features/scan/presentation/smart_scan_page.dart';
import '../../features/settings/presentation/privacy_policy_page.dart';
import '../../features/large_files/presentation/file_search_page.dart';
import '../../features/settings/presentation/about_page.dart';
import '../../features/settings/presentation/appearance_page.dart';
import '../../features/settings/presentation/scan_preferences_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/storage/presentation/storage_page.dart';
import '../widgets/app_page_transition.dart';
import 'app_routes.dart';
import 'redirect.dart';

/// Các tab chính đổi tức thì (thanh điều hướng đứng yên); màn phụ trượt nhẹ.
CustomTransitionPage<Object?> _fade(
  GoRouterState state,
  Widget child, {
  Offset from = const Offset(0, 0.045),
}) =>
    fadeSlidePage<Object?>(key: state.pageKey, child: child, from: from);

NoTransitionPage<Object?> _plain(GoRouterState state, Widget child) =>
    NoTransitionPage<Object?>(key: state.pageKey, child: child);

/// Điều hướng toàn app. Redirect chạy lại mỗi khi trạng thái onboarding,
/// phiên đăng nhập hoặc quyền ảnh thay đổi.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.uri.path,
      onboardingSeen: ref.read(onboardingSeenProvider),
      photoAccessPromptSeen: ref.read(photoAccessPromptSeenProvider),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _fade(state, Theme(data: AppTheme.light(), child: const OnboardingStep1Page())),
        routes: [
          GoRoute(
            path: '2',
            pageBuilder: (context, state) => _fade(
              state,
              Theme(data: AppTheme.light(), child: const OnboardingStep2Page()),
              from: const Offset(0.06, 0),
            ),
          ),
          GoRoute(
            path: '3',
            pageBuilder: (context, state) => _fade(
              state,
              Theme(data: AppTheme.light(), child: const OnboardingStep3Page()),
              from: const Offset(0.06, 0),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _plain(state, const HomePage()),
      ),
      GoRoute(
        path: AppRoutes.storage,
        pageBuilder: (context, state) => _plain(state, const StoragePage()),
      ),
      GoRoute(
        path: AppRoutes.help,
        pageBuilder: (context, state) => _fade(state, const HelpFeedbackPage()),
      ),
      GoRoute(
        path: AppRoutes.activity,
        pageBuilder: (context, state) => _plain(state, const ActivityPage()),
      ),
      GoRoute(
        path: AppRoutes.cleanupHistory,
        pageBuilder: (context, state) =>
            _fade(state, const CleanupHistoryPage()),
      ),
      GoRoute(
        path: '/activity/history/:id',
        pageBuilder: (context, state) => _fade(
          state,
          CleanupSessionPage(
            sessionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _plain(state, const SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (context, state) =>
            _fade(state, const PrivacyPolicyPage()),
      ),
      GoRoute(
        path: AppRoutes.appearanceSettings,
        pageBuilder: (context, state) =>
            _fade(state, const AppearancePage()),
      ),
      GoRoute(
        path: AppRoutes.scanPreferences,
        pageBuilder: (context, state) =>
            _fade(state, const ScanPreferencesPage()),
      ),
      GoRoute(
        path: AppRoutes.fileSearch,
        pageBuilder: (context, state) => _fade(state, const FileSearchPage()),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (context, state) => _fade(state, const AboutPage()),
      ),
      GoRoute(
        path: AppRoutes.scan,
        pageBuilder: (context, state) => _fade(
          state,
          const SmartScanPage(),
          from: const Offset(0, 0.06),
        ),
      ),
      GoRoute(
        path: AppRoutes.scanComplete,
        pageBuilder: (context, state) => _fade(state, const ScanCompletePage()),
      ),
      GoRoute(
        path: AppRoutes.scanEmpty,
        pageBuilder: (context, state) => _fade(state, const ScanEmptyPage()),
      ),
      GoRoute(
        path: AppRoutes.scanPartial,
        pageBuilder: (context, state) => _fade(state, const ScanPartialPage()),
      ),
      GoRoute(
        path: AppRoutes.scanError,
        pageBuilder: (context, state) => _fade(state, const ScanErrorPage()),
      ),
      GoRoute(
        path: AppRoutes.cleanupReview,
        pageBuilder: (context, state) =>
            _fade(state, const ReviewCleanupPage()),
      ),
      GoRoute(
        path: AppRoutes.cleanupProgress,
        pageBuilder: (context, state) => _fade(state, const CleaningPage()),
      ),
      GoRoute(
        path: AppRoutes.cleanupComplete,
        pageBuilder: (context, state) =>
            _fade(state, const CleanupCompletePage()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _fade(state, const NotificationsPage()),
      ),
      GoRoute(
        path: AppRoutes.notificationCleanup,
        pageBuilder: (context, state) =>
            _fade(state, const CleanupDetailPage()),
      ),
      GoRoute(
        path: AppRoutes.notificationStorage,
        pageBuilder: (context, state) =>
            _fade(state, const StorageWarningPage()),
      ),
      GoRoute(
        path: AppRoutes.notificationReminder,
        pageBuilder: (context, state) => _fade(state, const ScanReminderPage()),
      ),
      GoRoute(
        path: AppRoutes.duplicates,
        pageBuilder: (context, state) =>
            _fade(state, const DuplicatePhotosPage()),
      ),
      GoRoute(
        path: AppRoutes.groupReview,
        pageBuilder: (context, state) => _fade(
          state,
          GroupReviewPage(groupId: state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.largeFiles,
        pageBuilder: (context, state) => _fade(state, const LargeFilesPage()),
      ),
      GoRoute(
        path: AppRoutes.photoLibrary,
        pageBuilder: (context, state) => _fade(state, const PhotoLibraryPage()),
      ),
      GoRoute(
        path: AppRoutes.appManager,
        pageBuilder: (context, state) => _fade(state, const AppManagerPage()),
      ),
      GoRoute(
        path: AppRoutes.storageAnalysis,
        pageBuilder: (context, state) =>
            _fade(state, const StorageAnalysisPage()),
      ),
      GoRoute(
        path: AppRoutes.fileAccess,
        pageBuilder: (context, state) => _fade(state, Theme(data: AppTheme.light(), child: const FileAccessPage())),
      ),
      GoRoute(
        path: AppRoutes.photoLimited,
        pageBuilder: (context, state) => _fade(state, Theme(data: AppTheme.light(), child: const PhotoLimitedPage())),
      ),
      GoRoute(
        path: AppRoutes.photoDenied,
        pageBuilder: (context, state) => _fade(state, Theme(data: AppTheme.light(), child: const PhotoDeniedPage())),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Cầu nối Riverpod → GoRouter: đổi trạng thái là router tính lại redirect.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<bool>(
      onboardingSeenProvider,
      (previous, next) => notifyListeners(),
    );
    ref.listen<bool>(
      photoAccessPromptSeenProvider,
      (previous, next) => notifyListeners(),
    );
  }
}
