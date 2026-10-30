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
  static String resendIn(int seconds) => 'Resend in ${seconds}s';
  static const termsUnavailable = 'Terms of Service aren\u2019t available yet.';

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

  static const signOut = 'Sign out';

  // File access
  static const fileAccessTitle = 'Access your files';
  static const fileAccessBody =
      'Cleanify needs access to your files so it can scan for duplicates, large files, and items you may no longer need.';
  static const fileAccessScope =
      'This permission only helps with file scanning and cleanup. You can still use other parts of the app without it.';
  static const fileAccessRowTitle = 'File access permissions';
  static const fileAccessRowBody =
      'Needed to scan your files, find duplicates, and show cleanup recommendations.';
  static const fileAccessNotRequested = 'Not requested';
  // KHÔNG có trong Figma: nhãn trạng thái sau khi đã xin quyền.
  static const fileAccessAllowed = 'Allowed';
  static const fileAccessLimited = 'Limited';
  static const fileAccessDenied = 'Denied';
  static const fileAccessNote =
      'Without this permission, Cleanify can still help with general app settings, storage summaries, and support resources.';
  static const skipForNow = 'Skip for now';

  // Photo library
  static const photoLibrary = 'Photo Library';
  static const photoLibrarySubtitle = 'Browse every photo and video';
  static String libraryCount(int n) => n == 1 ? '1 item' : '$n items';
  static const libraryEmptyTitle = 'No photos or videos yet';
  static const libraryEmptyBody =
      'Photos and videos on this device will show up here.';
  static const libraryNoAccessTitle = 'Photo access is off';
  static const libraryNoAccessBody =
      'Allow access to browse your photos and videos here.';
  static const libraryErrorTitle = 'Can\u2019t open your library';
  static const libraryErrorBody =
      'Your photo library is temporarily unavailable. Try again in a moment.';
  static const libraryLoadFailed = 'Couldn\u2019t load this photo.';
  static const video = 'Video';

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

  // Storage tab
  static const storageTabBody = 'What is taking up space on this device';
  static const freeUpSpace = 'Free up space';
  static const noScanYetShort = 'Run a scan to see what can be cleaned.';
  static const capacity = 'Capacity';

  // Settings tab
  static const settingsTabBody = 'Make Cleanify work the way you want';
  static const settingsAccount = 'Account';
  static const settingsSignIn = 'Sign in';
  static const settingsSignInBody =
      'Optional. Your scans and settings stay on this device.';
  static const settingsSigned = 'Signed in as';
  static const signedOut = 'Signed out.';
  static const settingsPreferences = 'Preferences';
  static const settingsNotifications = 'Notifications';
  static const settingsNotificationsBody =
      'In-app scan reminders and storage alerts';
  static const settingsLanguage = 'Language';
  static const languageEnglish = 'English';
  static const languageVietnamese = 'Tiếng Việt';
  static const languageSoon = 'Soon';
  static const settingsPrivacy = 'Privacy';
  static const settingsPrivacyPolicy = 'Privacy Policy';
  static const settingsRestore = 'Restore Purchases';
  static const restoreUnavailable = 'Purchases aren\u2019t available yet.';
  static const settingsAbout = 'About';
  static const settingsVersion = 'Version 0.1.0';
  static const privacyPolicyTitle = 'Privacy Policy';
  static const privacyPolicyBody =
      'Cleanify scans the media on your device to find duplicates, similar photos, large videos and screenshots.\n\n'
      'Scanning happens on your device. Your photos and videos are not uploaded to our servers.\n\n'
      'Cleanify deletes media only after you confirm your selection, and the operating system asks you to confirm again.\n\n'
      'Settings and scan history are stored locally on your device. Removing the app clears them.\n\n'
      'Questions about this policy? Contact support@cleanify.app.';

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
  static const scanForJunk = 'Scan for Junk';
  static const recentNotifications = 'View Recent Notifications';
  static const largeFiles = 'Large Files';
  static String filterLabel(String size) => '>$size filter';
  static const cleanUp = 'Clean Up';
  static const deepAudit = 'Deep audit inspection & file history';
  static const navClean = 'Clean';
  static const legendPhotos = 'Photos';
  static const legendVideos = 'Videos';
  static String freeHeadroom(String size) => '$size Free headroom';
  static String moreSets(int n) => '+$n sets';

  // Quét
  static const smartScan = 'Scan';
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

  // ── Home sub-screens (Notifications, Duplicate Photos, Large Files...) ──
  static const selectAll = 'Select all';
  static const deselectAll = 'Deselect all';
  static const viewNow = 'View now';
  static const scanNowShort = 'Scan now';
  static const rescanShort = 'Scan again';

  static const notifTitle = 'Notifications';
  static const notifMarkAllRead = 'Mark all as read';
  static const notifToday = 'Today';
  static const notifReminders = 'Reminders';
  static const notifEmptyTitle = 'No notifications yet';
  static const notifEmptyBody =
      'Scan and cleanup notifications will appear here.';
  static const notifCleanupTitle = 'Cleanup complete';
  static String notifCleanupBody(int count, String size) =>
      'Cleaned $count items, about $size.';
  static String notifDuplicatesTitle(int groups) =>
      'Found $groups duplicate groups';
  static String notifDuplicatesBody(String size) => 'About $size can be freed.';
  static String notifLargeTitle(int count, String threshold) =>
      '$count large videos over $threshold';
  static String notifLargeBody(String size) =>
      'Taking up $size. Review and remove the ones you don\u2019t need.';
  static String notifStorageTitle(int percent) => 'Storage $percent% used';
  static String notifStorageBody(String free) =>
      'Only $free left. Consider cleaning up soon.';
  static const notifReminderTitle = 'No scan this session';
  static const notifReminderBody =
      'Scan for duplicates, large videos and screenshots.';

  static const filterAll = 'All';
  static const filterExact = 'Exact';
  static const filterSimilar = 'Similar';
  static String groupsReclaimable(int n) => '$n groups \u00b7 reclaimable';
  static String groupTitle(int index, int count) =>
      'Group $index \u00b7 $count photos';
  static const keepBadge = 'Keep';
  static const keepBadgeHint = 'The best photo is kept by default';
  static const pickPhotosToDelete = 'Select photos to delete';
  static String deletePhotos(int n, String size) =>
      'Delete $n photos \u00b7 $size';
  static const dupEmptyTitle = 'No duplicates';
  static const dupNotScannedTitle = 'No scan results yet';
  static const dupNotScannedBody =
      'Scan your library to find duplicate and similar photos.';

  static String largeVideosCount(int n) => '$n large videos';
  static const pickVideosToDelete = 'Select videos to delete';
  static String deleteVideos(int n, String size) =>
      'Delete $n videos \u00b7 $size';
  static const largeEmptyTitle = 'No videos found';
  static const largeEmptyBody = 'No videos exceed this threshold.';

  static const appManagerAlbums = 'By album';
  static const appManagerCaption = 'photos & videos, grouped by source';
  static const appManagerHint =
      'The operating system doesn\u2019t expose per-app storage. Cleanify groups library photos and videos by source album (WhatsApp, Telegram\u2026) and counts items.';
  static String albumItems(int n) => '$n items';
  static const albumsEmptyTitle = 'No albums yet';
  static const albumsEmptyBody = 'Photo access is needed to list albums.';
  static const albumsError = 'Couldn\u2019t load albums.';

  static const analysisFreeable = 'Can be freed';
  static const analysisSuggestions = 'Suggestions';
  static const analysisTotalMedia = 'Total photos & videos';
  static const analysisUsedOfTotal = 'used';
  static String analysisFreeOf(String free, String total) =>
      '$free free of $total';
  static const analysisNoScan =
      'Scan your library to see how much space can be freed.';
  static const suggestDuplicates = 'Remove duplicates';
  static const suggestLarge = 'Review large videos';

  static const cleanupDetailTitle = 'Cleanup Complete';
  static const cleanupDetailReclaimed = 'was freed';
  static const cleanupDetailItems = 'Items cleaned';
  static const cleanupDetailWhere = 'Temporary location';
  static const cleanupDetailWhereIos = 'Recently Deleted';
  static const cleanupDetailWhereAndroid = 'Trash';
  static const cleanupDetailEmpty = 'No cleanup in this session yet.';
  static const viewRemainingDuplicates = 'View remaining duplicates';

  static const storageWarnTitle = 'Storage Almost Full';
  static const storageWarnHeadline = 'Running low on space';
  static String storageWarnBody(String free, String total) =>
      '$free free of $total. When storage is almost full, your phone may slow down and you may not be able to save new photos.';
  static const storageWarnFreeNow = 'Can be freed now';
  static const storageWarnTotal = 'Total recoverable';
  static const storageWarnAnalysis = 'Storage analysis';

  static const reminderTitle = 'Scan Reminder';
  static const reminderNever = 'No scan this session';
  static const reminderNeverBody =
      'Scan to refresh duplicates, large videos and screenshots.';
  static const reminderDone = 'Scan complete';
  static const reminderDoneBody = 'You can scan again at any time.';
  static const reminderInfoTitle = 'About reminders';
  static const reminderInfoBody =
      'Cleanify currently reminds you only in the app. Periodic push notifications will come in a later update.';
}
