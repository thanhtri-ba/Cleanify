abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const createAccount = '/create-account';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const photoAccess = '/photo-access';
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

  static const authRoutes = {
    signIn,
    createAccount,
    forgotPassword,
    verifyEmail
  };
}
