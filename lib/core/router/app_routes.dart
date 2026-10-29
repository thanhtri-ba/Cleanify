abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const onboarding2 = '/onboarding/2';
  static const onboarding3 = '/onboarding/3';
  static const signIn = '/sign-in';
  static const createAccount = '/create-account';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const photoAccess = '/photo-access';
  static const fileAccess = '/file-access';
  static const home = '/home';
  static const storage = '/storage';
  static const settings = '/settings';
  static const scan = '/scan';
  static const scanComplete = '/scan/complete';
  static const scanEmpty = '/scan/empty';
  static const scanPartial = '/scan/partial';
  static const scanError = '/scan/error';
  static const cleanupReview = '/cleanup/review';
  static const cleanupProgress = '/cleanup/progress';
  static const cleanupComplete = '/cleanup/complete';
  static const notifications = '/notifications';
  static const notificationCleanup = '/notifications/cleanup';
  static const notificationStorage = '/notifications/storage';
  static const notificationReminder = '/notifications/reminder';
  static const duplicates = '/duplicates';
  static const largeFiles = '/large-files';
  static const photoLibrary = '/photo-library';
  static const appManager = '/app-manager';
  static const storageAnalysis = '/storage-analysis';

  static const authRoutes = {
    signIn,
    createAccount,
    forgotPassword,
    verifyEmail
  };
}
