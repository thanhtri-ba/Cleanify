/// Chuỗi giao diện (tiếng Anh, đúng theo Figma).
/// TODO: chuyển sang ARB / gen-l10n khi làm màn Language.
abstract final class AppStrings {
  static const appName = 'Cleanify';
  static const skip = 'Skip';
  static const back = 'Back';

  // Onboarding
  static const onboarding1Title = 'A Cleaner Phone Starts Here';
  static const onboarding1Body =
      'Free up space and keep your storage organized effortlessly.';
  static const onboarding2Title = 'Find & Remove Similar Photos';
  static const onboarding2Body =
      'Instantly detect duplicate pictures, blurry shots, and heavy screenshots to reclaim gigabytes.';
  static const onboarding3Title = 'Smart Protection & Private Vault';
  static const onboarding3Body =
      'Secure sensitive media in an encrypted vault while keeping your storage automatically optimized.';
  static const getStarted = 'Get Started';
  static const haveAccount = 'I already have an account';
  static const continueLabel = 'Continue';
  static const startFreeTrial = 'Start Free Trial';
  static const restorePurchases = 'Restore Purchases';
  static const termsAndPrivacy = 'Terms & Privacy';
  static const cleanableBadge = '+4.8 GB Cleanable';

  // Chung cho form
  static const emailLabel = 'Email address';
  static const emailHint = 'you@example.com';
  static const passwordLabel = 'Password';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
  static const orContinueWith = 'or continue with';
  static const continueWithGoogle = 'Continue with Google';
  static const signInWithApple = 'Sign in with Apple';
  static const continueWithFacebook = 'Continue with Facebook';

  // Sign in
  static const signInTitle = 'Welcome back';
  static const signInSubtitle =
      'Sign in to your Cleanify account. A little less clutter, a little more space.';
  static const passwordHintSignIn = 'Enter your password';
  static const forgotPasswordLink = 'Forgot password?';
  static const signInButton = 'Sign In';
  static const newToCleanify = 'New to Cleanify? ';
  static const createAccountLink = 'Create account';
  static const privacyReassurance = 'Your media stays yours. Always.';

  // Create account
  static const createTitle = 'Create your account';
  static const createSubtitle = 'Make room for what matters.';
  static const fullNameLabel = 'Full name';
  static const fullNameHint = 'Your name';
  static const passwordHintCreate = 'Create a password';
  static const passwordRule =
      'Use at least 8 characters, with an uppercase letter, a lowercase letter and a number.';
  static const termsPrefix =
      'By creating an account or continuing with a provider, you agree to our ';
  static const termsOfService = 'Terms of Service';
  static const termsMiddle = ' and acknowledge our ';
  static const privacyPolicy = 'Privacy Policy';
  static const createButton = 'Create Account';
  static const alreadyHaveAccount = 'Already have an account? ';
  static const signInLink = 'Sign in';

  // Forgot password
  static const forgotTitle = 'Forgot your password?';
  static const forgotSubtitle =
      'No worries. Enter your account email and we’ll help you reset your password.';
  static const sendResetLink = 'Send Reset Link';
  static const forgotNote =
      'Use the email you registered with. For Google, Apple or Facebook accounts, sign in with that provider instead.';
  static const backToSignInLink = 'Back to sign in';
  // KHÔNG có trong Figma: thông báo sau khi gửi link đặt lại mật khẩu.
  static const resetSent =
      'If an account exists for that email, a reset link is on its way.';

  // Verify email
  static const verifyTitle = 'Check your email';
  static const verifySubtitle =
      'One more step to your Cleanify account. Verify your email address to finish signing up.';
  static const verificationPending = 'Verification pending';
  static const yourEmailAddress = 'Your email address';
  static const verifyInstruction =
      'Look for a Cleanify verification link in your inbox, then return here to sign in.';
  static const changeEmail = 'Change email';
  static const verifyNote =
      'Can’t find it? Check your spam or junk folder, or request another verification email.';
  static const resendVerification = 'Resend Verification Email';
  static const backToSignInButton = 'Back to Sign In';
  // KHÔNG có trong Figma.
  static const verificationSent = 'Verification email sent.';

  // Lỗi (KHÔNG có trong Figma, cần designer xác nhận nội dung và kiểu hiển thị)
  static const errEmailRequired = 'Enter your email address.';
  static const errEmailInvalid = 'Enter a valid email address.';
  static const errPasswordRequired = 'Enter your password.';
  static const errNameRequired = 'Enter your name.';
  static const errNameTooLong = 'That name is too long.';
  static const errInvalidCredentials = 'Incorrect email or password.';
  static const errEmailInUse =
      'An account with this email already exists. Try signing in instead.';
  static const errEmailNotVerified = 'Please verify your email to continue.';
  static const errNetwork =
      'Can’t connect right now. Check your connection and try again.';
  static const errTooManyRequests =
      'Too many attempts. Please wait a moment and try again.';
  static const errUnknown = 'Something went wrong. Please try again.';

  // Home tạm thời
  static const homePlaceholderTitle = 'Home';
  static const homePlaceholderBody = 'Màn Home sẽ được dựng ở mục tiếp theo.';
  static const signOut = 'Sign out';

  // Photo access (section 09)
  static const photoAccessTitle = 'Photos & Videos';
  static const accessIntroTitle = 'Make room for memories';
  static const accessIntroBody =
      'Let Cleanify scan your photos and videos to find duplicates and large videos worth reviewing.';
  static const accessBenefit1Title = 'Find the space you can reclaim';
  static const accessBenefit1Body =
      'Spot similar photos and large videos in your library.';
  static const accessBenefit2Title = 'Private by design';
  static const accessBenefit2Body =
      'Scanning happens on your device. Your media isn\u2019t uploaded.';
  static const accessBenefit3Title = 'You decide what goes';
  static const accessBenefit3Body =
      'Nothing is deleted without your explicit confirmation.';
  static const accessNextIos = 'Next, iOS will ask what Cleanify can access.';
  static const accessNextAndroid =
      'Next, Android will ask to let Cleanify access your photos and videos.';
  static const notNow = 'Not Now';

  static const limitedTitle = 'Your selection, your control';
  static const limitedBody =
      'Cleanify can scan only the photos and videos you\u2019ve selected. The rest of your library stays out of reach.';
  static const limitedCaption = 'Limited access';
  static const limitedBadge = 'Selected only';
  static const limitedScopeTitle = 'Scan your selected media';
  static const limitedScopeBody =
      'Duplicate checks and large-video results include only the items you\u2019ve shared.';
  static const limitedNote =
      'Missing something from the scan? Add more photos or videos to your selection at any time.';
  static const manageSelectedMedia = 'Manage Selected Media';
  static const continueWithSelected = 'Continue with Selected Media';

  static const deniedTitle = 'Photo access is off';
  static const deniedBody =
      'Cleanify can\u2019t scan your photos or videos until you allow access. You can change this in Settings.';
  static const deniedCaption = 'Access denied';
  static const deniedUnavailableTitle = 'Media cleanup is unavailable';
  static const deniedUnavailableBody =
      'Duplicate photo checks, large-video scans and media cleanup recommendations are paused.';
  static const deniedHowToTitleIos = 'Allow access in iOS Settings';
  static const deniedHowToIos =
      'Cleanify \u2192 Photos \u2192 choose limited or full access.';
  static const deniedHowToTitleAndroid = 'Allow access in Settings';
  static const deniedHowToAndroid =
      'Settings \u2192 Apps \u2192 Cleanify \u2192 Permissions \u2192 Photos and videos.';
  static const deniedNote =
      'You can still view storage summaries, adjust app settings and get support without photo access.';
  static const openSettings = 'Open Settings';
  static const continueWithoutAccess = 'Continue Without Access';

  // Điều hướng chung
  static const navHome = 'Home';
  static const navScan = 'Scan';
  static const navStorage = 'Storage';
  static const navSettings = 'Settings';
  static const backToHome = 'Back to Home';
  static const comingSoon = 'Coming soon';

  // Home
  static const recentActivity = 'Recent activity';
  static const systemCapacity = 'System Capacity';
  static const used = 'USED';
  static const storageDistribution = 'Storage Distribution';
  static const legendUsed = 'Used';
  static const legendFree = 'Free';
  static const storageUnavailable = 'Storage info is unavailable right now.';
  static const retry = 'Retry';
  static const scanPhotosVideos = 'Scan Photos & Videos';
  static const duplicatePhotos = 'Duplicate Photos';
  static const review = 'Review';
  static const largeVideos = 'Large Videos';
  static const inspect = 'Inspect';
  static const appManager = 'App Manager';
  static const reviewApps = 'Review Apps';
  static const storageAnalysis = 'Storage Analysis';
  static const storageOverview = 'Storage overview & usage';
  static const noScanYet = 'Run a scan to find duplicate and similar photos.';
  static const noDuplicatesFound = 'No duplicate or similar photos found.';
  static String freeHeadroom(String size) => '$size Free headroom';
  static String moreSets(int n) => '+$n sets';

  // Quét
  static const smartScan = 'Smart Scan';
  static const scanningTitle = 'Scanning your photos & videos';
  static const scanningSubtitle = 'Analyzing accessible media';
  static const itemsChecked = 'Items checked';
  static const categories = 'Categories';
  static const estimatedSpace = 'Estimated space';
  static const categoriesExamined = 'Categories being examined';
  static const provisionalFindings = 'Provisional scan findings';
  static const scanningStatus = 'Scanning...';
  static const doneStatus = 'Done';
  static const pendingStatus = 'Pending';
  static const stopScan = 'Stop Scan';
  static const screenshots = 'Screenshots';
  static const similarPhotos = 'Similar Photos';
  static const hintDuplicatesScanning = 'Exact copies in your library';
  static const hintSimilarScanning = 'Near-duplicate moments';
  static const hintScreenshotsScanning = 'Captured moments to review';
  static const hintSimilarResult = 'Similar moments to compare';
  static const hintScreenshotsResult = 'Captures to review';
  static String hintVideos(String threshold) => 'Videos over $threshold';
  static String identicalShots(int n) =>
      n == 1 ? '1 identical shot' : '$n identical shots';

  // Scan complete
  static const scanComplete = 'Scan Complete';
  static const scanCompleteTitle = 'Scan complete \u2014 ready for review';
  static const scanCompleteBody =
      'We found items worth reviewing before cleanup. Nothing is deleted until you confirm.';
  static const potentialSpace = 'Potential space to free up';
  static const selectedForReview = 'Selected for review';
  static const nothingDeletedUntilConfirm =
      'Nothing is deleted until you confirm.';
  static String reviewSelection(String size) => 'Review Selection ($size)';
  static const notScanned = 'Pending';

  // Review cleanup
  static const reviewCleanup = 'Review Cleanup';
  static const oneLastLook = 'One last look';
  static const oneLastLookBody =
      'Review your selection before continuing. Nothing has been deleted yet.';
  static const selectedForCleanup = 'Selected for cleanup';
  static String categoriesSelected(int n) =>
      n == 1 ? '1 category selected' : '$n categories selected';
  static const wantToKeep = 'Want to keep something?';
  static const changeSelection = 'Change Selection';
  static const whatHappensNext = 'What happens next';
  static const whatHappensIos =
      'iOS will ask you to confirm deletion. Confirmed photos and videos move to Recently Deleted. With iCloud Photos, deletion also affects your synced devices.';
  static const whatHappensAndroid =
      'Android will ask you to confirm deletion. Confirmed photos and videos move to Trash and are removed permanently after a while.';
  static const nextConfirmIos = 'Next: confirm your deletion with iOS.';
  static const nextConfirmAndroid = 'Next: confirm your deletion with Android.';

  // Cleaning
  static const cleaningStorage = 'Cleaning Storage';
  static const makingRoom = 'Making room for what matters';
  static const processingConfirmed = 'Processing confirmed photos & videos';
  static const waitingConfirmation = 'Waiting for your confirmation';
  static const inProgress = 'IN PROGRESS';
  static const mediaProcessed = 'Media processed';
  static const itemsSelected = 'Items selected';
  static const remaining = 'Remaining';
  static const cleaningProgress = 'Cleaning progress';
  static const pauseCleanup = 'Pause Cleanup';
  static const pausing = 'Pausing\u2026';
  static const deletionNotConfirmed =
      'Deletion was not confirmed. Nothing was deleted.';

  // Cleanup complete
  static const cleanupComplete = 'Cleanup Complete';
  static const cleanupCompleteTitle = 'Your cleanup is complete';
  static const cleanupPartialTitle = 'Cleanup partly complete';
  static const cleanupPartialBody =
      'Some items were not deleted. Nothing else was changed, and you can review and try again.';
  static const movedIos =
      'Your confirmed photos and videos have been moved to Recently Deleted.';
  static const movedAndroid =
      'Your confirmed photos and videos have been moved to Trash.';
  static const reviewedMediaMoved = 'Reviewed media moved';
  static const itemsProcessed = 'Items processed';
  static const cleanupSummary = 'Cleanup summary';
  static const completed = 'Completed';
  static const needRecover = 'Need to recover something?';
  static const recoverIos =
      'Open Photos \u2192 Recently Deleted to recover media while it\u2019s still there. Cleanup History is a record, not a backup.';
  static const recoverAndroid =
      'Open your gallery app \u2192 Trash to recover media while it\u2019s still there. Cleanup History is a record, not a backup.';
  static String storageNoteIos(String size) =>
      'Available device storage updates after permanent removal from Recently Deleted; $size may not be free yet.';
  static String storageNoteAndroid(String size) =>
      'Available device storage updates after permanent removal from Trash; $size may not be free yet.';
  static const viewCleanupHistory = 'View Cleanup History';

  // Scan error
  static const storageScan = 'Storage Scan';
  static const scanErrorTitle = "We couldn't finish the scan.";
  static const scanErrorBody =
      'Your photo library is temporarily unavailable. Try again in a moment.';
  static const tryAgain = 'Try Again';
  static const scanErrorSafe =
      'No photos or videos were deleted. You can safely retry.';
  static const backToScan = 'Back to Scan';

  // No items
  static const noItemsTitle = 'No items to clean';
  static const noItemsBody =
      'No duplicates or other cleanup suggestions were found in the media scanned.';
  static const suggestedCleanup = 'Suggested cleanup';
  static const scanResults = 'Scan results';
  static String checkedOf(int done, int total) => '$done of $total checked';
  static const noneFound = 'None found';
  static const authorizedOnlyTitle = 'Only your authorized media was scanned';
  static const authorizedOnlyBody =
      'With limited access, this result covers only your selected photos and videos, not your entire library.';
  static const scanAgain = 'Scan Again';

  // Partial
  static const scanInterrupted = 'Scan Interrupted';
  static const partialBadge = 'PARTIAL RESULTS';
  static const partialTitle = 'Some results are ready';
  static const partialBody =
      'Your photo library became temporarily unavailable. The scan stopped, but completed results are saved.';
  static const availableToReview = 'Available to review';
  static const partialSubtotal = 'Partial subtotal only';
  static const categoriesFinished = 'Categories finished';
  static const completedValid = 'Completed \u00b7 valid results';
  static const notFullyScanned = 'Not fully scanned';
  static const partialSafe =
      'No files have been deleted. Retry to finish the remaining categories.';
  static const reviewAvailable = 'Review Available Results';
  static const retryRemaining = 'Retry Remaining Scan';

  static const startCleanup = 'Start Cleanup';
  static const reviewRemaining = 'Review Remaining';
  static const cleanupStopped = 'Cleanup stopped before finishing.';
  static const cleanupFailed =
      'Something went wrong while deleting. Items already removed stay removed.';
  static const settingsPlaceholderBody =
      'Settings will be available in a later update.';
  static const storagePlaceholderBody =
      'Storage overview will be available in a later update.';
}
