import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:upgrader/upgrader.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/home_page.dart';
import '../../features/meetings/presentation/bloc/emergency_share_bloc.dart';
import '../../features/meetings/presentation/pages/emergency_share_page.dart';
import '../../features/meetings/presentation/pages/live_location_page.dart';
import '../../features/meetings/presentation/pages/meeting_setup_page.dart';
import '../../features/meetings/presentation/pages/meetings_list_page.dart';
import '../../features/member_search/domain/entities/member_entity.dart';
import '../../features/member_search/presentation/pages/member_search_page.dart';
import '../../features/messaging/domain/entities/message_entity.dart';
import '../../features/messaging/presentation/pages/chat_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '../../features/messaging/presentation/pages/users_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/add_review_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/reviews_page.dart';
import '../../features/profile/presentation/cubit/current_user_cubit.dart';
import '../../features/profile/presentation/cubit/submit_review_cubit.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/emergency_contacts_page.dart';
import '../../features/settings/presentation/pages/personal_info_page.dart';
import '../../features/settings/presentation/pages/policy_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/gps_tracking/presentation/bloc/gps_tracking_bloc.dart';
import '../../features/sos/presentation/bloc/sos_bloc.dart';
import '../../features/sos/presentation/pages/sos_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/subscription/presentation/cubit/current_subscription_cubit.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/verification/presentation/pages/verification_page.dart';
import '../../features/verification/presentation/pages/verification_status_page.dart';
import '../dependency_injection/injection_container.dart';
import '../services/fcm_service.dart';
import '../services/secure_storage_service.dart';
import '../shared/widgets/custom_upgrade_alert.dart';
import 'app_routes.dart';
import 'route_observer.dart';
import '../../features/verification/presentation/bloc/verification_bloc.dart';

final _upgrader = Upgrader(
  debugLogging: false,
  debugDisplayAlways: false,
  
);

class AppRouter {
  final SecureStorageService _storage;
  AppRouter(this._storage);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: _guard,
    observers: [appRouteObserver],
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
        builder: (_, __) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: const RegisterPage(),
        ),
      ),

      // ── Shell (bottom nav) ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MultiBlocProvider(
          providers: [
            // Singleton cubits (see injection_container.dart) — already
            // provided at the app root (main.dart) too; `.value` here just
            // re-exposes the same instance to this subtree without ever
            // closing it when the shell rebuilds/disposes. `.load()` is a
            // cheap no-op re-entrancy guard if it's already loaded/loading.
            BlocProvider.value(value: sl<CurrentUserCubit>()..load()),
            BlocProvider.value(value: sl<CurrentSubscriptionCubit>()..load()),
          ],
          child: CustomUpgradeAlert(
            upgrader: _upgrader,
            showIgnore: false,
            showLater: false,
            child: AppShellPage(navigationShell: shell),
          ),
        ),
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
                builder: (_, state) => MemberSearchPage(
                  initialTab: state.uri.queryParameters['tab'],
                ),
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
                builder: (_, __) => BlocProvider(
                  create: (_) => sl<AuthBloc>(),
                  child: const ProfilePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
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
        builder: (_, __) => BlocProvider.value(
          value: sl<VerificationBloc>(),
          child: const VerificationPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.verificationStatus,
        builder: (_, __) => BlocProvider.value(
          value: sl<VerificationBloc>(),
          child: const VerificationStatusPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.meetings,
        builder: (_, state) => MeetingsListPage(
          initialTab: state.uri.queryParameters['tab'],
        ),
      ),
      GoRoute(
        path: AppRoutes.meetingSetup,
        builder: (_, state) {
          final memberId = state.uri.queryParameters['memberId'];
          final partner =
              state.extra is MemberEntity ? state.extra as MemberEntity : null;
          return MeetingSetupPage(partnerId: memberId, partner: partner);
        },
      ),
      GoRoute(
        path: AppRoutes.liveLocation,
        builder: (_, __) => const LiveLocationPage(),
      ),
      GoRoute(
        path: '${AppRoutes.liveLocation}/:id',
        builder: (_, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<EmergencyShareBloc>()),
            BlocProvider(create: (_) => sl<GpsTrackingBloc>()),
          ],
          child: LiveLocationPage(meetingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.emergencyShare}/:id',
        builder: (_, state) => BlocProvider(
          create: (_) => sl<EmergencyShareBloc>(),
          child: EmergencySharePage(meetingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.sos,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          // /sos is a top-level route outside the shell's IndexedStack, so
          // it doesn't inherit the shell's CurrentSubscriptionCubit
          // provider — SosPage's Trusted Contact Alerts gate needs it too.
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<SosBloc>()),
              BlocProvider.value(value: sl<CurrentSubscriptionCubit>()..load()),
            ],
            child: const SosPage(),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.sos}/:id',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<SosBloc>()),
              BlocProvider.value(value: sl<CurrentSubscriptionCubit>()..load()),
            ],
            child: SosPage(meetingId: state.pathParameters['id']),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, state) {
          final extra = state.extra;
          final initialPlanSlug = extra is String ? extra : null;
          return SubscriptionPage(initialPlanSlug: initialPlanSlug);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.reviews,
        builder: (_, __) => const ReviewsPage(),
      ),
      GoRoute(
        path: AppRoutes.addReview,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<SubmitReviewCubit>(),
          child: AddReviewPage(args: state.extra as AddReviewArgs),
        ),
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

  Future<String?> _guard(BuildContext context, GoRouterState state) async {
    final isAuth = await _storage.isAuthenticated();

    // Fire-and-forget: turns on push notifications (permission request,
    // token registration, tap-navigation listeners) the moment we know the
    // user is authenticated. initialize() is idempotent, so re-running it
    // on every navigation is harmless.
    if (isAuth) {
      unawaited(sl<FcmService>().initialize());
      // Warms the shared current-subscription cache right after auth is
      // confirmed. load() is a no-op re-entrancy guard + cache read when
      // already loaded/fresh, so calling it on every navigation is cheap.
      unawaited(sl<CurrentSubscriptionCubit>().load());
    }

    final preAuthRoutes = {
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.register,
    };

    final isPreAuth = preAuthRoutes.contains(state.matchedLocation);

    // Not authenticated → send to login (except pre-auth screens)
    if (!isAuth && !isPreAuth) return AppRoutes.login;

    // Authenticated → block access to login/register screens
    if (isAuth &&
        isPreAuth &&
        state.matchedLocation != AppRoutes.splash &&
        state.matchedLocation != AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    // Unverified users are blocked from Safee-PIN search, creating/joining/
    // managing meetings (+ history), SOS, and chat — this is the backstop
    // for every entry point (deep links, notification taps, back
    // navigation), on top of the tap-level requireVerification() checks that
    // also show the "Verification Required" snackbar before redirecting.
    if (isAuth &&
        _isVerificationRestricted(state.matchedLocation) &&
        state.matchedLocation != AppRoutes.verification) {
      final verified = await _isVerifiedUser(context.read<CurrentUserCubit>());
      if (!verified) return AppRoutes.verification;
    }

    return null;
  }

  static const _verificationRestrictedPrefixes = [
    AppRoutes.memberSearch, // == AppRoutes.search
    AppRoutes.meetingSetup,
    AppRoutes.meetings,
    AppRoutes.sos,
    AppRoutes.reviews,
    AppRoutes.chat, // prefix also covers /chat/:id and /chat/new
  ];

  bool _isVerificationRestricted(String location) =>
      _verificationRestrictedPrefixes.any(
          (prefix) => location == prefix || location.startsWith('$prefix/'));

  Future<bool> _isVerifiedUser(CurrentUserCubit cubit) async {
    if (cubit.state.profile == null) {
      // This runs on the navigation-critical path (every tap into a
      // restricted route blocks here until this resolves), so it must
      // never hang navigation indefinitely on a slow/unresponsive network —
      // bound the wait and fall through to `cubit.isVerified` below on
      // timeout. That still evaluates to false here (profile is still
      // null), i.e. the same fail-closed outcome the real request would
      // eventually reach anyway if it kept failing — this only stops the
      // UI from freezing while waiting to find that out. The load already
      // kicked off keeps running in the background regardless, so the very
      // next navigation attempt picks up the real result once it lands.
      try {
        if (cubit.state.status == CurrentUserStatus.loading) {
          await cubit.stream
              .firstWhere(
                (s) => s.profile != null || s.status == CurrentUserStatus.error,
              )
              .timeout(const Duration(seconds: 5));
        } else {
          await cubit.load().timeout(const Duration(seconds: 5));
        }
      } on TimeoutException {
        // Handled by falling through to `cubit.isVerified` below.
      }
    }
    return cubit.isVerified;
  }
}
