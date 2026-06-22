import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no
// ProfileBloc/repository wiring, so it never hits the (currently
// unavailable) backend. Re-connect it to ProfileBloc (ProfileLoadRequested)
// once the backend is ready.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DarkScreenHeader(
              title: 'My Profile',
              centerTitle: true,
              titleFontSize: 18,
              trailing: GestureDetector(
                onTap: () => context.push(AppRoutes.settings),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                ),
              ),
              child: const _ProfileAvatarSection(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PinCard(),
                  const SizedBox(height: 16),
                  const _StatsRow(),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.verificationStatus),
                    child: const _TrustScoreRow(),
                  ),
                  const SizedBox(height: 16),
                  const _CurrentPlanCard(),
                  const SizedBox(height: 16),
                  AppListCard(children: [
                    _NavTile(
                      icon: Icons.shield,
                      iconColor: AppColors.success,
                      label: 'Verification Status',
                      subtitle: 'Level 2 Verified',
                      onTap: () => context.push(AppRoutes.verificationStatus),
                    ),
                    _NavTile(
                      icon: Icons.star,
                      iconColor: AppColors.warning,
                      label: 'Reviews & Ratings',
                      subtitle: '47 reviews · 4.9 avg',
                      onTap: () => context.push(AppRoutes.reviews),
                    ),
                    _NavTile(
                      icon: Icons.workspace_premium,
                      iconColor: AppColors.purple,
                      label: 'Membership & Billing',
                      subtitle: 'Premium plan',
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                    _NavTile(
                      icon: Icons.settings,
                      iconColor: AppColors.textSecondary,
                      label: 'Settings & Privacy',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reviews',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.reviews),
                        child: Text('See all',
                            style: GoogleFonts.inter(
                                color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _ReviewPreview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarSection extends StatelessWidget {
  const _ProfileAvatarSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.person, color: Colors.white70, size: 44),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkBg, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Alex Johnson',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('alex.johnson@email.com', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        const SizedBox(height: 2),
        Text('+1 (555) 123-4567', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _Badge(emoji: '🟢', label: 'Level 1', color: AppColors.success),
            SizedBox(width: 8),
            _Badge(emoji: '🔵', label: 'Level 2', color: AppColors.blue),
            SizedBox(width: 8),
            _Badge(emoji: null, label: 'Premium', color: AppColors.purple),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String? emoji;
  final String label;
  final Color color;
  const _Badge({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 11)), const SizedBox(width: 5)],
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFEE PIN',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text('#SM-7821',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Share your PIN to let others verify you',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: QrImageView(data: '#SM-7821', version: QrVersions.auto, size: 200),
                ),
              ),
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.darkBg, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.qr_code_2, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCard(icon: Icons.calendar_today, value: '47', label: 'Meetings', color: AppColors.blue)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.shield, value: '94', label: 'Trust Score', color: AppColors.success)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.star, value: '4.9', label: 'Rating', color: AppColors.warning)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TrustScoreRow extends StatelessWidget {
  const _TrustScoreRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  value: 0.94,
                  strokeWidth: 5,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Text('94', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trust Score',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Based on verification level, meeting history & reviews',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT PLAN',
                  style: GoogleFonts.inter(
                      color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                Text('Premium', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Renews Jul 10, 2026', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.subscription),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Upgrade',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 19),
            ),
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

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFDCEBFF), shape: BoxShape.circle),
                child: const Center(child: Text('😊', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sarah M.',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: List.generate(
                          5, (i) => const Icon(Icons.star, color: AppColors.warning, size: 13)),
                    ),
                  ],
                ),
              ),
              Text('Jun 9', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Alex was incredibly professional and trustworthy. Felt completely safe during our meeting.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
