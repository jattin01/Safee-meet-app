import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../core/services/google_auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _darkMode;
  late bool _locationEnabled;
  late bool _sosAlertsEnabled;

  @override
  void initState() {
    super.initState();
    final hive = sl<HiveService>();
    _darkMode = hive.isDarkMode;
    _locationEnabled = hive.isLocationPermGranted;
    _sosAlertsEnabled = hive.isSosAlertsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DarkScreenHeader(title: 'Settings', titleFontSize: 21, child: _ProfileMiniCard()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('ACCOUNT'),
                  const SizedBox(height: 10),
                  AppListCard(children: [
                    _NavTile(
                      icon: Icons.person_outline,
                      iconColor: AppColors.blue,
                      label: 'Personal Information',
                      subtitle: 'Name, email, phone',
                      onTap: () => context.push(AppRoutes.personalInfo),
                    ),
                    _NavTile(
                      icon: Icons.phone_outlined,
                      iconColor: AppColors.success,
                      label: 'Emergency Contacts',
                      subtitle: '3 contacts configured',
                      onTap: () => context.push(AppRoutes.emergencyContacts),
                    ),
                    _NavTile(
                      icon: Icons.credit_card,
                      iconColor: AppColors.warning,
                      label: 'Subscription & Billing',
                      subtitle: 'Premium · Renews Jul 10',
                      onTap: () => context.push(AppRoutes.subscription),
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
                      subtitle: 'Level 2 Verified',
                      onTap: () => context.push(AppRoutes.verificationStatus),
                    ),
                    _NavTile(
                      icon: Icons.lock_outline,
                      iconColor: AppColors.purple,
                      label: 'Change Password',
                      subtitle: 'Last changed 30 days ago',
                      onTap: () => context.push(AppRoutes.changePassword),
                    ),
                    _ToggleTile(
                      icon: Icons.public,
                      iconColor: AppColors.teal,
                      label: 'Location Permissions',
                      subtitle: 'Allow SAFEE MEET to access location',
                      value: _locationEnabled,
                      onChanged: (v) {
                        setState(() => _locationEnabled = v);
                        sl<HiveService>().setLocationPermGranted(v);
                      },
                    ),
                    _ToggleTile(
                      icon: Icons.notifications_none,
                      iconColor: AppColors.primary,
                      label: 'SOS Notifications',
                      subtitle: 'Emergency alert confirmations',
                      value: _sosAlertsEnabled,
                      onChanged: (v) {
                        setState(() => _sosAlertsEnabled = v);
                        sl<HiveService>().setSosAlertsEnabled(v);
                      },
                    ),
                  ]),
                  // const SizedBox(height: 24),
                  // const _Label('APPEARANCE'),
                  // const SizedBox(height: 10),
                  // AppListCard(children: [
                  //   _ToggleTile(
                  //     icon: Icons.dark_mode_outlined,
                  //     iconColor: AppColors.textSecondary,
                  //     label: 'Dark Mode',
                  //     subtitle: 'Switch to dark theme',
                  //     value: _darkMode,
                  //     onChanged: (v) {
                  //       setState(() => _darkMode = v);
                  //       sl<HiveService>().setDarkMode(v);
                  //     },
                  //   ),
                  // ]),
                  const SizedBox(height: 24),
                  const _Label('LEGAL'),
                  const SizedBox(height: 10),
                  AppListCard(children: [
                    _NavTile(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.textSecondary,
                      label: 'Privacy Policy',
                      onTap: () => context.push('${AppRoutes.policy}?type=privacy'),
                    ),
                    _NavTile(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.textSecondary,
                      label: 'Terms of Service',
                      onTap: () => context.push('${AppRoutes.policy}?type=terms'),
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
                        border: Border.all(color: AppColors.error.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), shape: BoxShape.circle),
                            child: Icon(Icons.logout, color: AppColors.error, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.inter(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'SAFEE MEET v2.4.1',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await sl<GoogleAuthService>().signOut();
    } catch (_) {
      // Ignore any sign-out failure and continue clearing local state.
    }
    await sl<SecureStorageService>().clearSession();
    context.read<AuthBloc>().add(const AuthResetRequested());
    context.go(AppRoutes.auth);
  }
}

class _ProfileMiniCard extends StatelessWidget {
  const _ProfileMiniCard();

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
            decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white70, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alex Johnson',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Premium · #SM-7821', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ],
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
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
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
                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
