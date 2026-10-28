import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session.dart';
import '../../features/auth/application/pending_verification.dart';
import '../../features/auth/presentation/create_account_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/auth/presentation/verify_email_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/scan/presentation/cleaning_page.dart';
import '../../features/scan/presentation/cleanup_complete_page.dart';
import '../../features/scan/presentation/no_items_page.dart';
import '../../features/scan/presentation/partial_results_page.dart';
import '../../features/scan/presentation/review_cleanup_page.dart';
import '../../features/scan/presentation/scan_complete_page.dart';
import '../../features/scan/presentation/scan_error_page.dart';
import '../../features/scan/presentation/smart_scan_page.dart';
import '../../features/settings/presentation/settings_placeholder_page.dart';
import '../../features/storage/presentation/storage_placeholder_page.dart';
import '../../features/onboarding/application/onboarding_state.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/permissions/application/media_access_controller.dart';
import '../../features/permissions/presentation/photo_access_page.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';
import 'redirect.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Cầu nối: khi trạng thái Riverpod đổi, buộc router chạy lại redirect.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, __) => refresh.value++);
  ref.listen(onboardingSeenProvider, (_, __) => refresh.value++);
  ref.listen(pendingVerificationEmailProvider, (_, __) => refresh.value++);
  ref.listen(photoAccessPromptSeenProvider, (_, __) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.uri.path,
      onboardingSeen: ref.read(onboardingSeenProvider),
      signedIn: ref.read(authSessionProvider) is SignedIn,
      pendingVerificationEmail: ref.read(pendingVerificationEmailProvider),
      photoAccessPromptSeen: ref.read(photoAccessPromptSeenProvider),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        builder: (context, state) => const CreateAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: AppRoutes.photoAccess,
        builder: (context, state) => const PhotoAccessPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.storage,
              builder: (context, state) => const StoragePlaceholderPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPlaceholderPage(),
            ),
          ]),
        ],
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
        builder: (context, state) => const NoItemsPage(),
      ),
      GoRoute(
        path: AppRoutes.scanPartial,
        builder: (context, state) => const PartialResultsPage(),
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
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
