import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/verification_gate.dart';
import '../../../../core/shared/widgets/app_logo_widget.dart';
import '../../../../core/shared/widgets/section_header.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';
import '../../../subscription/presentation/cubit/current_subscription_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _refresh(BuildContext context) =>
      context.read<CurrentUserCubit>().load(forceRefresh: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<CurrentUserCubit, CurrentUserState>(
        builder: (context, state) {
          if (state.status == CurrentUserStatus.loading &&
              state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CurrentUserStatus.error &&
              state.profile == null) {
            return _HomeErrorState(
              message: state.errorMessage ??
                  'Unable to load your profile right now.',
              onRetry: () => _refresh(context),
            );
          }

          final profile = state.profile!;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _refresh(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DarkHeader(profile: profile),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.status == CurrentUserStatus.error &&
                            state.errorMessage != null) ...[
                          _InlineWarning(message: state.errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        SectionHeader(title: 'Quick Actions'),
                        const _QuickActions(),
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Safety Center'),
                        const _SafetyCenter(),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Meeting Activity',
                          actionLabel: 'See all',
                          onAction: () {
                            if (!requireVerification(context)) return;
                            context.push(AppRoutes.meetings);
                          },
                        ),
                        _MeetingSyncCard(profile: profile),
                        const SizedBox(height: 24),
                        BlocBuilder<CurrentSubscriptionCubit,
                            CurrentSubscriptionState>(
                          builder: (context, subState) =>
                              _UpgradeCard(state: subState),
                        ),
                        const SizedBox(height: 100),
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
}

class _HomeErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                color: AppColors.textTertiary, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;
  const _InlineWarning({required this.message});

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
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
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

class _DarkHeader extends StatelessWidget {
  final ProfileEntity profile;
  const _DarkHeader({required this.profile});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _verificationLabel {
    if (profile.verificationStatus == 'not_submitted') return 'Unverified';
    return switch (profile.verificationLevel) {
      'high' => 'Level 3 Verified',
      'medium' => 'Level 2 Verified',
      'low' => 'Level 1 Verified',
      _ => 'Verification Pending',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppLogoWidget(
                  size: LogoSize.sm, variant: LogoVariant.light),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBg2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: profile.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    profile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        profile.initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    profile.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.darkBg2, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _greeting,
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _HeaderBadge(
                            label: _verificationLabel,
                            color: AppColors.blue,
                            textColor: AppColors.blueLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${profile.trustScore}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'TRUST',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.calendar_today,
                          iconColor: AppColors.primary,
                          value: '${profile.totalMeetings}',
                          label: 'Meetings',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.star,
                          iconColor: const Color(0xFFFBBF24),
                          value: '${profile.safetyScore}',
                          label: 'Safety',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.person_search,
                          iconColor: const Color(0xFFFBBF24),
                          value: '${profile.pinSearchCount}',
                          label: 'Safee PIN Searches',
                        ),
                      ),
                    ],
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

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _HeaderBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    _QuickAction(
      icon: Icons.shield_outlined,
      label: 'Verify',
      color: AppColors.primary,
      route: AppRoutes.verification,
    ),
    _QuickAction(
      icon: Icons.search,
      label: 'Search',
      color: AppColors.blue,
      route: AppRoutes.memberSearch,
    ),
    _QuickAction(
      icon: Icons.qr_code_scanner,
      label: 'Scan QR',
      color: AppColors.purple,
      route: '${AppRoutes.memberSearch}?tab=qr',
    ),
    _QuickAction(
      icon: Icons.event_outlined,
      label: 'Meeting',
      color: AppColors.success,
      route: AppRoutes.meetingSetup,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: _actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: _actions.last == action ? 0 : 10,
                  ),
                  child: _QuickActionTile(action: action),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (action.label == 'Verify') {
          openVerificationScreen(context);
          return;
        }
        // Search / Scan QR / Meeting all lead to verification-gated
        // features — Verify itself must stay reachable regardless.
        if (!requireVerification(context)) return;
        context.push(action.route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(action.icon, color: action.color, size: 24),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _SafetyCenter extends StatelessWidget {
  const _SafetyCenter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SafetyRow(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primary.withOpacity(0.1),
            title: 'Emergency SOS',
            subtitle: 'Tap to activate an emergency alert',
            onTap: () {
              if (!requireVerification(context)) return;
              context.push(AppRoutes.sos);
            },
          ),
          const _RowDivider(),
          _SafetyRow(
            icon: Icons.people_outline,
            iconColor: AppColors.blue,
            iconBg: AppColors.blue.withOpacity(0.1),
            title: 'Trusted Contacts',
            subtitle: 'Manage emergency contacts and alerts',
            onTap: () => context.push(AppRoutes.emergencyContacts),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderLight);
  }
}

class _SafetyRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SafetyRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _MeetingSyncCard extends StatelessWidget {
  final ProfileEntity profile;
  const _MeetingSyncCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!requireVerification(context)) return;
        context.push(AppRoutes.meetings);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_note, color: AppColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting history sync',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.totalMeetings > 0
                        ? 'You have ${profile.totalMeetings} meetings recorded. Detailed history will appear here as dashboard data becomes available.'
                        : 'No live meeting history is available from the current profile API yet.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final CurrentSubscriptionState state;
  const _UpgradeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final sub = state.subscription;
    final hasPaidAccess = sub?.hasActiveAccess ?? false;
    final isFree = !hasPaidAccess;
    // Already on the highest-tier plan (by sortOrder, cross-checked against
    // the live plan catalog) — there's nothing left to upgrade to, so no
    // upgrade CTA is shown at all, just the plan itself.
    final isHighestPlan = state.isOnHighestPlan;
    final planName = sub?.planLabel ?? 'Free';

    final String title;
    final String subtitle;
    if (isHighestPlan) {
      title = '$planName Plan';
      subtitle = "You're on our top plan — all features unlocked";
    } else if (isFree) {
      title = 'Free Plan';
      subtitle = 'Unlock more trust and safety features';
    } else {
      title = '$planName Plan';
      subtitle = 'Review billing and subscription details';
    }

    return GestureDetector(
      onTap: isHighestPlan ? null : () => context.push(AppRoutes.subscription),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isHighestPlan ? Icons.workspace_premium : Icons.trending_up,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!isHighestPlan)
              const Icon(Icons.chevron_right, color: Colors.white60, size: 22),
          ],
        ),
      ),
    );
  }
}
