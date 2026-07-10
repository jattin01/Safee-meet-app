abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth/login';    // alias
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Shell (bottom-nav) branches
  static const String shell = '/';
  static const String home = '/home';
  static const String dashboardHome = '/home'; // alias
  static const String memberSearch = '/search';
  static const String search = '/search';      // alias
  static const String conversations = '/chat';
  static const String chat = '/chat';          // alias
  static const String newChat = '/chat/new';
  static const String profile = '/profile';
  static const String more = '/settings';      // 5th tab

  // Settings
  static const String settings = '/settings';

  // Feature routes
  static const String verification = '/verification';
  static const String verificationStatus = '/verification/status';
  static const String meetingSetup = '/meetings/setup';
  static const String meetings = '/meetings';
  static const String activeMeeting = '/meetings/active';
  static const String liveLocation = '/live-location';
  static const String sos = '/sos';
  static const String subscription = '/subscription';
  static const String notifications = '/notifications';
  static const String reviews = '/reviews';

  // Settings sub-screens
  static const String personalInfo = '/settings/personal-info';
  static const String emergencyContacts = '/settings/emergency-contacts';
  static const String changePassword = '/settings/change-password';
  static const String policy = '/settings/policy';
  static const String privacyPolicy = '/settings/policy?type=privacy';
  static const String termsOfService = '/settings/policy?type=terms';
}
