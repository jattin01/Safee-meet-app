import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/meetings/presentation/pages/active_meeting_page.dart';
import '../../features/meetings/presentation/pages/meeting_setup_page.dart';
import '../../features/meetings/presentation/pages/meetings_list_page.dart';
import '../../features/member_search/presentation/pages/member_search_page.dart';
import '../../features/messaging/domain/entities/message_entity.dart';
import '../../features/messaging/presentation/pages/chat_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '../../features/messaging/presentation/pages/users_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/reviews_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/emergency_contacts_page.dart';
import '../../features/settings/presentation/pages/personal_info_page.dart';
import '../../features/settings/presentation/pages/policy_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/sos/presentation/pages/sos_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/verification/presentation/pages/verification_page.dart';
import '../../features/verification/presentation/pages/verification_status_page.dart';
import '../dependency_injection/injection_container.dart';
import '../services/secure_storage_service.dart';
import 'app_routes.dart';

class AppRouter {
  final SecureStorageService _storage;
  AppRouter(this._storage);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: _guard,
    routes: [
      // ── Pre-auth ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),

      // ── Shell (bottom nav) ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShellPage(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, __) => const MemberSearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (_, __) => const ConversationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                // Settings still dispatches AuthResetRequested on sign-out.
                builder: (_, __) => BlocProvider(
                  create: (_) => sl<AuthBloc>(),
                  child: const SettingsPage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Feature Routes ────────────────────────────────────────────────────
      // Chat detail is a top-level route (outside the shell) so it renders
      // without the bottom navigation bar.
      GoRoute(
        path: AppRoutes.newChat,
        builder: (_, __) => const UsersPage(),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:conversationId',
        builder: (_, state) => ChatPage(
          conversationId: state.pathParameters['conversationId']!,
          conversation: state.extra as ConversationEntity?,
        ),
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (_, __) => const VerificationPage(),
      ),
      GoRoute(
        path: AppRoutes.verificationStatus,
        builder: (_, __) => const VerificationStatusPage(),
      ),
      GoRoute(
        path: AppRoutes.meetings,
        builder: (_, __) => const MeetingsListPage(),
      ),
      GoRoute(
        path: AppRoutes.meetingSetup,
        builder: (_, state) {
          final memberId = state.uri.queryParameters['memberId'];
          return MeetingSetupPage(partnerId: memberId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.activeMeeting}/:id',
        builder: (_, state) => ActiveMeetingPage(meetingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.sos,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SosPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, __) => const SubscriptionPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.reviews,
        builder: (_, __) => const ReviewsPage(),
      ),

      // ── Settings sub-screens ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (_, __) => const PersonalInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.emergencyContacts,
        builder: (_, __) => const EmergencyContactsPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, __) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.policy,
        builder: (_, state) {
          final type = state.uri.queryParameters['type'] ?? 'privacy';
          return PolicyPage(type: type);
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );

  // PROTOTYPE MODE: the auth guard is disabled so every screen is reachable
  // without a real login/register network call (login_page.dart and
  // register_page.dart currently skip AuthBloc entirely, so no access token
  // is ever saved). Restore the checks below once those pages are wired
  // back up to AuthBloc and validation is re-enabled.
  Future<String?> _guard(BuildContext context, GoRouterState state) async {
    return null;
    // final isAuth = await _storage.isAuthenticated();
    // final isPreAuth = [
    //   AppRoutes.splash,
    //   AppRoutes.onboarding,
    //   AppRoutes.login,
    //   AppRoutes.register,
    // ].contains(state.matchedLocation);
    //
    // if (!isAuth && !isPreAuth) return AppRoutes.login;
    // if (isAuth &&
    //     isPreAuth &&
    //     state.matchedLocation != AppRoutes.splash &&
    //     state.matchedLocation != AppRoutes.onboarding) {
    //   return AppRoutes.home;
    // }
    // return null;
  }
}
