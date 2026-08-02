import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CurrentUserCubit>()..load(),
      child: const _PersonalInfoView(),
    );
  }
}

class _PersonalInfoView extends StatelessWidget {
  const _PersonalInfoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocBuilder<CurrentUserCubit, CurrentUserState>(
        builder: (context, state) {
          if (state.status == CurrentUserStatus.loading &&
              state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CurrentUserStatus.error &&
              state.profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ??
                          'Unable to load personal information.',
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
            );
          }

          final profile = state.profile!;

          return RefreshIndicator(
            onRefresh: () =>
                context.read<CurrentUserCubit>().load(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DarkScreenHeader(title: 'Personal Information'),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, 24, 20, context.bottomSafePadding(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: AppColors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: profile.avatarUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          profile.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _AvatarFallback(profile: profile),
                                        ),
                                      )
                                    : _AvatarFallback(profile: profile),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Profile data is synced from your account',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppListCard(
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              value: profile.name,
                            ),
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              value: profile.email ?? 'Not available',
                            ),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Mobile Number',
                              value: profile.phone ?? 'Not available',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppListCard(
                          header: 'ACCOUNT INFO',
                          children: [
                            _PlainRow(
                                label: 'SAFEE PIN',
                                value: '#${profile.safeePIN}'),
                            _PlainRow(
                              label: 'Member Since',
                              value: _memberSince(profile),
                            ),
                            _PlainRow(
                              label: 'Account Status',
                              value: _accountStatus(profile),
                              valueColor: _accountStatusColor(profile),
                              valueIcon: _accountStatusIcon(profile),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _memberSince(ProfileEntity profile) {
    final createdAt = profile.createdAt;
    if (createdAt == null) return 'Not available';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String _accountStatus(ProfileEntity profile) => switch (profile.status) {
        'active' => 'Active',
        'pending' => 'Pending',
        'suspended' => 'Suspended',
        'blocked' => 'Blocked',
        _ => 'Unknown',
      };

  Color _accountStatusColor(ProfileEntity profile) => switch (profile.status) {
        'active' => AppColors.success,
        'pending' => AppColors.warning,
        'suspended' || 'blocked' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  IconData? _accountStatusIcon(ProfileEntity profile) =>
      switch (profile.status) {
        'active' => Icons.check,
        'pending' => Icons.schedule,
        'suspended' || 'blocked' => Icons.block,
        _ => null,
      };
}

class _AvatarFallback extends StatelessWidget {
  final ProfileEntity profile;
  const _AvatarFallback({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        profile.initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? valueIcon;

  const _PlainRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueIcon,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = valueColor ?? AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (valueIcon != null) ...[
            Icon(valueIcon, color: displayColor, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            style: GoogleFonts.inter(
              color: displayColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
