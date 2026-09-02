import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/utils/verification_gate.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/shared/widgets/section_header.dart';
import '../../../../core/shared/widgets/skeleton_item.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';
import '../../../subscription/presentation/cubit/current_subscription_cubit.dart';
import 'package:safee_meet/core/shared/widgets/app_snackbar.dart';

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) {
    if (context.mounted) {
      AppSnackbar.info(context, 'Could not open link.');
    }
    return;
  }
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  late bool _locationEnabled;
  late bool _sosAlertsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final hive = sl<HiveService>();
    _locationEnabled = hive.isLocationPermGranted;
    _sosAlertsEnabled = hive.isSosAlertsEnabled;
    _syncLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User may have changed the permission from device Settings and come back.
    if (state == AppLifecycleState.resumed) {
      _syncLocationPermission();
    }
  }

  Future<void> _syncLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!mounted) return;
    setState(() => _locationEnabled = granted);
    await sl<HiveService>().setLocationPermGranted(granted);
  }

  Future<void> _onLocationToggle(bool v) async {
    if (v) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final open = await _confirmOpenSettings(
          title: 'Location Services Off',
          message:
              'Turn on location services on your device to allow SAFEE MEET to access your location.',
          actionLabel: 'Open Settings',
        );
        if (open) await Geolocator.openLocationSettings();
        await _syncLocationPermission();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        final open = await _confirmOpenSettings(
          title: 'Location Permission Blocked',
          message:
              'Location access is permanently denied. Enable it from app Settings to continue.',
          actionLabel: 'Open App Settings',
        );
        if (open) await Geolocator.openAppSettings();
        await _syncLocationPermission();
        return;
      }

      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!mounted) return;
      setState(() => _locationEnabled = granted);
      await sl<HiveService>().setLocationPermGranted(granted);
      if (!granted && mounted) {
        AppSnackbar.info(context, 'Location permission was not granted.');
      }
    } else {
      final open = await _confirmOpenSettings(
        title: 'Turn Off Location',
        message:
            'Location access can only be revoked from your device Settings. Open Settings now?',
        actionLabel: 'Open App Settings',
      );
      if (open) await Geolocator.openAppSettings();
      await _syncLocationPermission();
    }
  }

  Future<bool> _confirmOpenSettings({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (!ctx.mounted) return;
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (!ctx.mounted) return;
              Navigator.pop(ctx, true);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentUserCubit, CurrentUserState>(
      builder: (context, state) {
        if (state.status == CurrentUserStatus.loading &&
            state.profile == null) {
          return const Scaffold(
            backgroundColor: AppColors.lightBg,
            body: _SettingsSkeletonState(),
          );
        }

        if (state.status == CurrentUserStatus.error && state.profile == null) {
          return Scaffold(
            backgroundColor: AppColors.lightBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? 'Unable to load your settings.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<CurrentUserCubit>()
                          .load(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = state.profile!;

        return Scaffold(
          backgroundColor: AppColors.lightBg,
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<CurrentUserCubit>().load(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DarkScreenHeader(
                    title: 'Settings',
                    titleFontSize: 21,
                    child: _ProfileMiniCard(profile: profile),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, 24, 20, context.bottomSafePadding(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.status == CurrentUserStatus.error &&
                            state.errorMessage != null) ...[
                          _SyncNotice(message: state.errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        const _Label('ACCOUNT'),
                        const SizedBox(height: 10),
                        AppListCard(children: [
                          _NavTile(
                            icon: Icons.person_outline,
                            iconColor: AppColors.blue,
                            label: 'Personal Information',
                            subtitle: _personalInfoSubtitle(profile),
                            onTap: () => context.push(AppRoutes.personalInfo),
                          ),
                          _NavTile(
                            icon: Icons.phone_outlined,
                            iconColor: AppColors.success,
                            label: 'Emergency Contacts',
                            subtitle: 'Manage emergency contacts',
                            onTap: () =>
                                context.push(AppRoutes.emergencyContacts),
                          ),
                          BlocBuilder<CurrentSubscriptionCubit,
                              CurrentSubscriptionState>(
                            builder: (context, subState) => _NavTile(
                              icon: Icons.credit_card,
                              iconColor: AppColors.warning,
                              label: 'Subscription & Billing',
                              subtitle: _subscriptionSubtitle(subState),
                              onTap: () => context.push(AppRoutes.subscription),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        const _Label('PRIVACY & SECURITY'),
                        const SizedBox(height: 10),
                        AppListCard(children: [
                          _NavTile(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.success,
                            label: 'Identity Verification',
                            subtitle:
                                _verificationLabel(profile.verificationLevel),
                            onTap: () => openVerificationScreen(context),
                          ),
                          // _NavTile(
                          //   icon: Icons.lock_outline,
                          //   iconColor: AppColors.purple,
                          //   label: 'Change Password',
                          //   subtitle: 'Manage password and sign-in security',
                          //   onTap: () => context.push(AppRoutes.changePassword),
                          // ),
                          _ToggleTile(
                            icon: Icons.public,
                            iconColor: AppColors.teal,
                            label: 'Location Permissions',
                            subtitle: 'Allow SAFEE MEET to access location',
                            value: _locationEnabled,
                            onChanged: _onLocationToggle,
                          ),
                          // _ToggleTile(
                          //   icon: Icons.notifications_none,
                          //   iconColor: AppColors.primary,
                          //   label: 'SOS Notifications',
                          //   subtitle: 'Emergency alert confirmations',
                          //   value: _sosAlertsEnabled,
                          //   onChanged: (v) {
                          //     setState(() => _sosAlertsEnabled = v);
                          //     sl<HiveService>().setSosAlertsEnabled(v);
                          //   },
                          // ),
                        ]),
                        const SizedBox(height: 24),
                        const _Label('LEGAL'),
                        const SizedBox(height: 10),
                        AppListCard(children: [
                          _NavTile(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.textSecondary,
                            label: 'Privacy Policy',
                            onTap: () => _openUrl(context,
                                'https://safeemeet.testingenv.co.in/privacy-policy'),
                          ),
                          _NavTile(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.textSecondary,
                            label: 'Terms of Service',
                            onTap: () => _openUrl(context,
                                'https://safeemeet.testingenv.co.in/terms-and-conditions'),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: AppColors.error,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sign Out',
                                  style: GoogleFonts.inter(
                                    color: AppColors.error,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'SAFEE MEET v2.4.1',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _personalInfoSubtitle(ProfileEntity profile) => <String>[
        profile.name,
        if ((profile.email ?? profile.phone) != null)
          profile.email ?? profile.phone!
      ].where((value) => value.trim().isNotEmpty).join(' · ');

  String? _subscriptionSubtitle(CurrentSubscriptionState state) {
    switch (state.status) {
      case CurrentSubscriptionStatus.initial:
      case CurrentSubscriptionStatus.loading:
        return 'Loading plan…';
      case CurrentSubscriptionStatus.error:
        return 'Manage your subscription';
      case CurrentSubscriptionStatus.loaded:
        final sub = state.subscription;
        if (state.noActiveSubscription || sub == null) return 'Manage your subscription plan';
        final suffix = sub.isCancelled
            ? ' (Cancelled)'
            : sub.isTrialing
                ? ' (Trial)'
                : '';
        return 'Current plan: ${sub.planLabel}$suffix';
    }
  }

  String _verificationLabel(String level) => switch (level) {
        'level3' => 'Level 3 Verified',
        'level2' => 'Level 2 Verified',
        'level1' => 'Level 1 Verified',
        _ => 'Unverified',
      };

  Future<void> _logout() async {
    try {
      await sl<GoogleAuthService>().signOut();
    } catch (_) {
      // Ignore any sign-out failure and continue clearing local state.
    }
    await sl<SecureStorageService>().clearSession();
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthResetRequested());
    context.go(AppRoutes.auth);
  }
}

class _ProfileMiniCard extends StatelessWidget {
  final ProfileEntity profile;

  const _ProfileMiniCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          profile.initials,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      profile.initials,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${profile.verificationLevel == 'level3' ? 'Level 3' : profile.verificationLevel == 'level2' ? 'Level 2' : profile.verificationLevel == 'level1' ? 'Level 1' : 'Unverified'} · #${profile.safeePIN}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncNotice extends StatelessWidget {
  final String message;
  const _SyncNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sync_problem, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _RowIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _RowIcon(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _RowIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsSkeletonState extends StatelessWidget {
  const _SettingsSkeletonState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.darkBg,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
          child: const SkeletonItem(width: 120, height: 28, borderRadius: 8, color: Colors.white12),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SkeletonItem(width: 100, height: 20, borderRadius: 6),
                const SizedBox(height: 12),
                const SkeletonItem(height: 80, borderRadius: 16),
                const SizedBox(height: 24),
                const SkeletonItem(width: 140, height: 20, borderRadius: 6),
                const SizedBox(height: 12),
                const SkeletonItem(height: 160, borderRadius: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
