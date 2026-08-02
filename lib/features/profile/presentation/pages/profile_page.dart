import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/utils/verification_gate.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../subscription/domain/entities/current_subscription_entity.dart';
import '../../../subscription/presentation/cubit/current_subscription_cubit.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../cubit/reviews_cubit.dart';

/// Renders the Safee PIN as a QR PNG and shares it together with the PIN
/// text through a single OS share sheet.
Future<void> _shareSafeePinAndScanner(BuildContext context, String? pin) async {
  if (pin == null || pin.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your Safee PIN isn\'t ready yet.')),
    );
    return;
  }
  try {
    final painter = QrPainter(
      data: pin,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(color: Color(0xFF000000)),
      dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF000000)),
    );

    // Paint onto an explicit white background ourselves — QrPainter only
    // draws the black modules and leaves everything else transparent, which
    // several share targets composite against black, making the code look
    // like a solid black square once shared.
    const size = 600.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = Colors.white,
    );
    painter.paint(canvas, const Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final imageData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = imageData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/safee_pin_qr.png').writeAsBytes(bytes);
    if (!context.mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'My Safee PIN is $pin. Scan the attached QR code to verify me on SafeeMeet.',
      subject: 'My Safee PIN & Scanner',
      sharePositionOrigin:
          box != null ? (box.localToGlobal(Offset.zero) & box.size) : null,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to share right now. Please try again.')),
      );
    }
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(const ProfileLoadRequested()),
        ),
        // Backs the review stats (rating/count) and the review preview
        // card below — both come from GET /v1/reviews, not from the
        // /v1/auth/me-backed ProfileBloc.
        BlocProvider(create: (_) => sl<ReviewsCubit>()..load()),
      ],
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _refresh(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    // Set the listener up before dispatching, so it can't miss the emission.
    final profileDone = profileBloc.stream
        .firstWhere((s) => s is ProfileLoaded || s is ProfileError);
    profileBloc.add(const ProfileLoadRequested());

    return Future.wait([
      profileDone,
      context.read<ReviewsCubit>().load(forceRefresh: true),
      context.read<CurrentSubscriptionCubit>().load(forceRefresh: true),
    ]);
  }

  String? _verificationLabel(String? level) => switch (level) {
        'high' => 'Level 3 Verified',
        'medium' => 'Level 2 Verified',
        'low' => 'Level 1 Verified',
        'none' => 'Not verified yet',
        _ => null,
      };

  String _membershipSubtitle(CurrentSubscriptionState state) {
    switch (state.status) {
      case CurrentSubscriptionStatus.initial:
      case CurrentSubscriptionStatus.loading:
        return 'Loading plan…';
      case CurrentSubscriptionStatus.error:
        return 'View billing details';
      case CurrentSubscriptionStatus.loaded:
        final sub = state.subscription;
        return sub == null ? 'Free plan' : '${sub.planLabel} plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state is ProfileLoaded ? state.profile : null;
        return BlocBuilder<ReviewsCubit, ReviewsState>(
          builder: (context, reviewsState) => _buildScaffold(
              context, profile, state is ProfileLoading, reviewsState),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ProfileEntity? profile,
    bool profileLoading,
    ReviewsState reviewsState,
  ) {
    final summary = reviewsState.summary;
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _refresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarkScreenHeader(
                title: 'My Profile',
                titleFontSize: 18,
                child: profileLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(color: Colors.white54),
                      )
                    : _ProfileAvatarSection(profile: profile),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, context.bottomSafePadding(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PinCard(pin: profile?.safeePIN),
                    const SizedBox(height: 16),
                    _StatsRow(
                      trustScore: profile?.trustScore ?? 0,
                      rating: summary?.averageRating ?? 0,
                      totalMeetings: profile?.totalMeetings ?? 0,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => openVerificationScreen(context),
                      child: _TrustScoreRow(
                        score: profile?.trustScore ?? 0,
                        level: profile?.verificationLevel ?? 'none',
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<CurrentSubscriptionCubit,
                        CurrentSubscriptionState>(
                      builder: (context, subState) =>
                          _CurrentPlanCard(state: subState),
                    ),
                    const SizedBox(height: 16),
                    AppListCard(children: [
                      _NavTile(
                        icon: Icons.ios_share,
                        iconColor: AppColors.primary,
                        label: 'Share Safee PIN & Scanner',
                        subtitle: 'Send your PIN and QR code',
                        onTap: () {
                          if (!requireVerification(context)) return;
                          _shareSafeePinAndScanner(context, profile?.safeePIN);
                        },
                      ),
                      _NavTile(
                        icon: Icons.shield,
                        iconColor: AppColors.success,
                        label: 'Verification Status',
                        subtitle:
                            _verificationLabel(profile?.verificationLevel),
                        onTap: () => openVerificationScreen(context),
                      ),
                      _NavTile(
                        icon: Icons.star,
                        iconColor: AppColors.warning,
                        label: 'Reviews & Ratings',
                        subtitle: summary != null
                            ? '${summary.totalReviews} reviews · ${summary.averageRating.toStringAsFixed(1)} avg'
                            : (reviewsState.status == ReviewsStatus.error
                                ? null
                                : 'Loading…'),
                        onTap: () {
                          if (!requireVerification(context)) return;
                          context.push(AppRoutes.reviews);
                        },
                      ),
                      BlocBuilder<CurrentSubscriptionCubit,
                          CurrentSubscriptionState>(
                        builder: (context, subState) => _NavTile(
                          icon: Icons.workspace_premium,
                          iconColor: AppColors.purple,
                          label: 'Membership & Billing',
                          subtitle: _membershipSubtitle(subState),
                          onTap: () => context.push(AppRoutes.subscription),
                        ),
                      ),
                    ]),
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

class _ProfileAvatarSection extends StatelessWidget {
  final ProfileEntity? profile;
  const _ProfileAvatarSection({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? '—';
    final email = profile?.email;
    final phone = profile?.phone;
    final avatar = profile?.avatarUrl;
    final level = profile?.verificationLevel ?? 'none';

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(22)),
              child: avatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              color: Colors.white70, size: 44)),
                    )
                  : const Icon(Icons.person, color: Colors.white70, size: 44),
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
        Text(name,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        if (email != null)
          Text(email,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        if (phone != null) ...[
          const SizedBox(height: 2),
          Text(phone,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (level == 'low' || level == 'medium' || level == 'high')
              const _Badge(
                  emoji: '🟢', label: 'Level 1', color: AppColors.success),
            if (level == 'medium' || level == 'high') ...[
              const SizedBox(width: 8),
              const _Badge(
                  emoji: '🔵', label: 'Level 2', color: AppColors.blue),
            ],
            if (level == 'high') ...[
              const SizedBox(width: 8),
              const _Badge(
                  emoji: '⭐', label: 'Level 3', color: AppColors.warning),
            ],
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
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 5)
          ],
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final String? pin;
  const _PinCard({this.pin});

  @override
  Widget build(BuildContext context) {
    final displayPin = pin?.isNotEmpty == true ? pin! : '—';
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
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text(displayPin,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Share your PIN to let others verify you',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: QrImageView(
                      data: displayPin, version: QrVersions.auto, size: 200),
                ),
              ),
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.qr_code_2, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int trustScore;
  final double rating;
  final int totalMeetings;
  const _StatsRow(
      {this.trustScore = 0, this.rating = 0, this.totalMeetings = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                icon: Icons.calendar_today,
                value: '$totalMeetings',
                label: 'Meetings',
                color: AppColors.blue)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                icon: Icons.shield,
                value: '$trustScore',
                label: 'Trust Score',
                color: AppColors.success)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                icon: Icons.star,
                value: rating.toStringAsFixed(1),
                label: 'Rating',
                color: AppColors.warning)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

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
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TrustScoreRow extends StatelessWidget {
  final int score;
  final String level;
  const _TrustScoreRow({this.score = 0, this.level = 'none'});

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);
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
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppColors.borderLight,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Text('$score',
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trust Score',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Based on verification level, meeting history & reviews',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
  final CurrentSubscriptionState state;
  const _CurrentPlanCard({required this.state});

  static String _formatDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  String? _subtitleFor(CurrentSubscriptionEntity sub) {
    if (sub.isCancelled && sub.renewsAt != null) {
      return 'Access ends ${_formatDate(sub.renewsAt!)}';
    }
    if (sub.isTrialing && sub.hasTrial) {
      return sub.renewsAt != null
          ? 'Trial · ${sub.trialDays}d · ends ${_formatDate(sub.renewsAt!)}'
          : 'Trial · ${sub.trialDays} days';
    }
    if (sub.hasActiveAccess && sub.renewsAt != null) {
      final cadence = sub.billingCycle == 'yearly' ? 'yr' : 'mo';
      return '\$${sub.price.toStringAsFixed(2)}/$cadence · Renews ${_formatDate(sub.renewsAt!)}';
    }
    if (!sub.hasActiveAccess) return sub.statusLabel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sub = state.subscription;
    final isLoading = state.status == CurrentSubscriptionStatus.loading &&
        !state.hasLoadedOnce;
    final label = isLoading ? '—' : (sub?.planLabel ?? 'Free');
    final hasPaidAccess = sub?.hasActiveAccess ?? false;
    final subtitle = isLoading
        ? 'Loading plan…'
        : (sub != null ? _subtitleFor(sub) : "You're on the Free plan");

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
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT PLAN',
                  style: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                ],
              ],
            ),
          ),
          // No plan above the user's current one — there's nothing left to
          // upgrade to, so the Upgrade/Manage CTA is hidden entirely and
          // only the plan itself (already rendered above) is shown.
          if (!state.isOnHighestPlan)
            GestureDetector(
              onTap: () => context.push(AppRoutes.subscription),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(hasPaidAccess ? 'Manage' : 'Upgrade',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check, color: AppColors.success, size: 18),
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
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 19),
            ),
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

