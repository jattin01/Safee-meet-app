abstract final class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://168.144.112.102:8080/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Secure Storage Keys ──────────────────────────────────────────────────
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId = 'user_id';
  static const String kUserPhone = 'user_phone';

  // ── Hive Box Names ───────────────────────────────────────────────────────
  static const String kSettingsBox = 'settings_box';
  static const String kUserBox = 'user_box';
  static const String kCacheBox = 'cache_box';
  static const String kNotificationsBox = 'notifications_box';

  // ── Hive Keys ────────────────────────────────────────────────────────────
  static const String kDarkMode = 'dark_mode';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kLocationPermGranted = 'location_perm_granted';
  static const String kSosAlertsEnabled = 'sos_alerts_enabled';

  // ── Socket ───────────────────────────────────────────────────────────────
  static const String socketUrl = 'https://socket.safeemeet.com';

  // ── App ──────────────────────────────────────────────────────────────────
  static const String appName = 'SAFEE MEET';
  static const String appVersion = '2.4.1';
  static const String tagline = 'Are you verified?';

  // ── Subscription Prices ──────────────────────────────────────────────────
  static const String freePriceMonthly = '\$0';
  static const String basicPriceMonthly = '\$9.99';
  static const String premiumPriceMonthly = '\$19.99';
  static const String professionalPriceMonthly = '\$39.99';
  static const String basicPriceYearly = '\$6.99';
  static const String premiumPriceYearly = '\$13.99';
  static const String professionalPriceYearly = '\$27.99';
  // Numeric equivalents for in-app calculations
  static const double basicMonthlyPrice = 9.99;
  static const double premiumMonthlyPrice = 19.99;
  static const double professionalMonthlyPrice = 39.99;
  static const double basicYearlyPrice = 83.88; // 6.99 * 12
  static const double premiumYearlyPrice = 167.88; // 13.99 * 12
  static const double professionalYearlyPrice = 335.88; // 27.99 * 12

  // ── Emergency ────────────────────────────────────────────────────────────
  static const int maxEmergencyContacts = 5;
  static const int sosCountdownSeconds = 5;
  static const int sosHoldDurationMs = 2000;

  // ── OTP ──────────────────────────────────────────────────────────────────
  static const int otpLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 60);

  // ── Validation ───────────────────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int passwordMinLength = 8; // alias
  static const int maxPasswordLength = 128;

  // ── Attachments ──────────────────────────────────────────────────────────
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxDocumentSizeBytes = 25 * 1024 * 1024; // 25 MB
  static const List<String> allowedImageExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif',
  ];
  static const List<String> allowedDocumentExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv',
  ];
  static const String chatAttachmentsStoragePath = 'chat_attachments';
}
