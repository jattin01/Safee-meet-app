import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/app_logo_widget.dart';
import '../../../../core/shared/widgets/section_header.dart';

// PROTOTYPE MODE: this page is a pixel-matching UI build of the Home screen
// design. It renders hard-coded mock data only — there is no DashboardBloc,
// no API/repository wiring, and no validation. Re-connect it to
// DashboardBloc (see dashboard_bloc.dart) once the backend is ready.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ── Mock data ────────────────────────────────────────────────────────────
  static const _userName = 'Alex Johnson';
  static const _userInitials = 'AJ';
  static const _verificationLabel = 'Level 2 Verified';
  static const _trustScore = 94;
  static const _meetingsCount = 47;
  static const _safetyRating = '4.9';
  static const _safeePin = '#SM-7821';
  static const _unreadNotifications = 3;
  static const _trustedContactsCount = 3;

  static const _meetings = [
    _MeetingMock(
      icon: Icons.coffee,
      iconColor: Color(0xFF64748B),
      iconBg: Color(0xFFE2E8F0),
      partnerName: 'Sarah Mitchell',
      subtitle: 'Jun 9 · Downtown Coffee',
      status: 'Completed',
      rating: '5.0',
    ),
    _MeetingMock(
      icon: Icons.park,
      iconColor: AppColors.success,
      iconBg: Color(0xFFDCFCE7),
      partnerName: 'James Carter',
      subtitle: 'Jun 7 · City Park',
      status: 'Completed',
      rating: '4.8',
    ),
    _MeetingMock(
      icon: Icons.shopping_bag,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFFEDD5),
      partnerName: 'Marketplace Item',
      subtitle: 'Jun 5 · Mall Entrance',
      status: 'Upcoming',
      rating: '—',
    ),
  ];

  // Prototype: simulates a network refresh so the pull-to-refresh UX can
  // still be demonstrated against the existing mock data, without a
  // backend to actually re-fetch from.
  Future<void> _refresh() => Future.delayed(const Duration(milliseconds: 700));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DarkHeader(
                userName: _userName,
                userInitials: _userInitials,
                verificationLabel: _verificationLabel,
                trustScore: _trustScore,
                meetingsCount: _meetingsCount,
                safetyRating: _safetyRating,
                safeePin: _safeePin,
                unreadNotifications: _unreadNotifications,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: 'Quick Actions'),
                    const _QuickActions(),
                    const SizedBox(height: 24),
                    SectionHeader(title: 'Safety Center'),
                    _SafetyCenter(trustedContactsCount: _trustedContactsCount),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent Meetings',
                      actionLabel: 'See all',
                      onAction: () => context.push(AppRoutes.meetings),
                    ),
                    ..._meetings.map((m) => _MeetingCard(meeting: m)),
                    const SizedBox(height: 24),
                    const _UpgradeCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingMock {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String partnerName;
  final String subtitle;
  final String status;
  final String rating;

  const _MeetingMock({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.partnerName,
    required this.subtitle,
    required this.status,
    required this.rating,
  });
}

class _DarkHeader extends StatelessWidget {
  final String userName;
  final String userInitials;
  final String verificationLabel;
  final int trustScore;
  final int meetingsCount;
  final String safetyRating;
  final String safeePin;
  final int unreadNotifications;

  const _DarkHeader({
    required this.userName,
    required this.userInitials,
    required this.verificationLabel,
    required this.trustScore,
    required this.meetingsCount,
    required this.safetyRating,
    required this.safeePin,
    required this.unreadNotifications,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none,
                          color: Colors.white, size: 20),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              '$unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                          child: Center(
                            child: Text(
                              userInitials,
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
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 12),
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
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  verificationLabel,
                                  style: const TextStyle(
                                    color: AppColors.blueLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
                            '$trustScore',
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
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.calendar_today,
                        iconColor: AppColors.primary,
                        value: '$meetingsCount',
                        label: 'Meetings',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.star,
                        iconColor: Color(0xFFFBBF24),
                        value: '$safetyRating★',
                        label: 'Safety',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.key,
                        iconColor: Color(0xFFFBBF24),
                        value: safeePin,
                        label: 'SAFEE PIN',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
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
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
      route: AppRoutes.memberSearch,
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
            .map((a) => Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: _actions.last == a ? 0 : 10),
                    child: _QuickActionTile(action: a),
                  ),
                ))
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
      onTap: () => context.push(action.route),
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
  final int trustedContactsCount;
  const _SafetyCenter({required this.trustedContactsCount});

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
            subtitle: 'Tap to activate emergency alert',
            onTap: () => context.push(AppRoutes.sos),
          ),
          const _RowDivider(),
          _SafetyRow(
            icon: Icons.location_on,
            iconColor: AppColors.success,
            iconBg: AppColors.success.withOpacity(0.1),
            title: 'Live Location',
            subtitle: 'Share real-time location',
            // No dedicated live-location screen yet — prototype only.
            onTap: () {},
          ),
          const _RowDivider(),
          _SafetyRow(
            icon: Icons.people_outline,
            iconColor: AppColors.blue,
            iconBg: AppColors.blue.withOpacity(0.1),
            title: 'Trusted Contacts',
            subtitle: '$trustedContactsCount contacts configured',
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
    return Divider(height: 1, thickness: 1, color: AppColors.borderLight);
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
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
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
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final _MeetingMock meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final isCompleted = meeting.status == 'Completed';
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: meeting.iconBg, shape: BoxShape.circle),
            child: Icon(meeting.icon, color: meeting.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.partnerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meeting.subtitle,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meeting.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                  const SizedBox(width: 3),
                  Text(
                    meeting.rating,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.subscription),
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
              child:
                  const Icon(Icons.trending_up, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Unlock background checks & trust score',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white60, size: 22),
          ],
        ),
      ),
    );
  }
}
