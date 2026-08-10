import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../domain/entities/verification_entity.dart';
import '../bloc/verification_bloc.dart';

class VerificationStatusPage extends StatefulWidget {
  const VerificationStatusPage({super.key});

  @override
  State<VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<VerificationStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationBloc>().add(const VerificationStatusRequested());
    });
  }

  Future<void> _refresh(BuildContext context) {
    final done = Completer<void>();
    context.read<VerificationBloc>().add(VerificationStatusRequested(done: done));
    return done.future;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationBloc, VerificationState>(
      builder: (context, state) {
        if (state is VerificationLoading || state is VerificationInitial) {
          return const Scaffold(
            backgroundColor: AppColors.lightBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is VerificationError) {
          return Scaffold(
            backgroundColor: AppColors.lightBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<VerificationBloc>()
                          .add(const VerificationStatusRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is! VerificationStatusLoaded) {
          return const Scaffold(
            backgroundColor: AppColors.lightBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final status = state.status;
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
                    title: 'Verification Status',
                    titleFontSize: 21,
                    childGap: 20,
                    child: _TrustScoreCard(status: status),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, 24, 20, context.bottomSafePadding(40)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusBanner(status: status),
                        const SizedBox(height: 16),
                        _LevelCard(
                          icon: Icons.shield,
                          color: status.level1Complete
                              ? AppColors.success
                              : AppColors.warning,
                          title: 'Level 1 Verification',
                          statusText: _level1Label(status),
                          badgeLabel: status.level1Complete
                              ? 'Verified'
                              : 'In Progress',
                          badgeColor: status.level1Complete
                              ? AppColors.success
                              : AppColors.warning,
                          items: [
                            _CheckItem('National ID uploaded',
                                done: status.currentStep !=
                                    VerificationStep.uploadId),
                            _CheckItem('Selfie submitted',
                                done: status.currentStep ==
                                        VerificationStep.processing ||
                                    status.currentStep ==
                                        VerificationStep.complete),
                            _CheckItem('Review complete',
                                done: status.level1Complete),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _LockedLevelCard(
                          title: 'Level 2 Verification',
                          subtitle:
                              'Background and enhanced checks can be added later',
                        ),
                        const SizedBox(height: 16),
                        const _LockedLevelCard(
                          title: 'Professional Verification',
                          subtitle:
                              'Business and credentials review is not enabled yet',
                        ),
                        const SizedBox(height: 20),
                        _SafetyScoreBreakdown(status: status),
                        const SizedBox(height: 24),
                        _ActionCard(status: status),
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

  String _level1Label(VerificationStatusEntity status) =>
      switch (status.kycStatus) {
        'approved' => 'Approved',
        'pending' => 'Pending review',
        'rejected' => 'Rejected',
        'draft' => 'Draft started',
        _ => 'Not started',
      };
}

class _TrustScoreCard extends StatelessWidget {
  final VerificationStatusEntity status;
  const _TrustScoreCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (status.trustScore / 100).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                // A lone Text as the Stack's only other child is centered by
                // `alignment: Alignment.center` on its own — no sibling
                // (like the label below) competing for vertical space, so
                // the number itself sits dead-center in the ring.
                Text(
                  '${status.trustScore}',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TRUST SCORE',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _headline(status),
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _subheadline(status),
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _MiniBadge(
                label: status.level1Complete
                    ? 'Level 1 Active'
                    : 'Level 1 Pending',
                color: status.level1Complete
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _MiniBadge(
                label: status.verificationLevel == 'none'
                    ? 'No badge yet'
                    : '${status.verificationLevel.toUpperCase()} tier',
                color: status.verificationLevel == 'high'
                    ? AppColors.blue
                    : AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _headline(VerificationStatusEntity status) =>
      switch (status.kycStatus) {
        'approved' => 'Identity verified',
        'pending' => 'Verification in review',
        'rejected' => 'Verification needs updates',
        'draft' => 'Verification draft saved',
        _ => 'Verification not started',
      };

  String _subheadline(VerificationStatusEntity status) =>
      switch (status.kycStatus) {
        'approved' => 'Your Level 1 verification is active',
        'pending' => 'Our team is reviewing your documents',
        'rejected' => 'Update and resubmit your documents',
        'draft' => 'Finish the remaining steps to submit',
        _ => 'Complete identity verification to earn trust',
      };
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final VerificationStatusEntity status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.kycStatus) {
      'approved' => AppColors.success,
      'pending' => AppColors.primary,
      'rejected' => AppColors.error,
      'draft' => AppColors.warning,
      _ => AppColors.textSecondary,
    };

    final title = switch (status.kycStatus) {
      'approved' => 'Approved',
      'pending' => 'Pending Review',
      'rejected' => 'Rejected',
      'draft' => 'Draft Saved',
      _ => 'Not Started',
    };

    final body =
        status.rejectionReason != null && status.rejectionReason!.isNotEmpty
            ? status.rejectionReason!
            : switch (status.kycStatus) {
                'approved' => 'Your documents and selfie passed review.',
                'pending' =>
                  'We have everything we need. Check back soon for the result.',
                'draft' => 'Upload the remaining items to submit for review.',
                'rejected' =>
                  'Your submission did not pass review. Please upload your documents again.',
                _ =>
                  'Complete Level 1 verification to strengthen your trust profile.',
              };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.kycStatus == 'approved'
                ? Icons.verified
                : status.kycStatus == 'rejected'
                    ? Icons.error_outline
                    : Icons.hourglass_top,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String text;
  final bool done;
  const _CheckItem(this.text, {required this.done});
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String statusText;
  final String badgeLabel;
  final Color badgeColor;
  final List<_CheckItem> items;

  const _LevelCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.statusText,
    required this.badgeLabel,
    required this.badgeColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(statusText,
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.inter(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              item.done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: item.done
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.text,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedLevelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _LockedLevelCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.14),
              shape: BoxShape.circle),
          child: const Icon(Icons.lock_outline, color: AppColors.warning),
        ),
        title: Text(title,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

class _SafetyScoreBreakdown extends StatelessWidget {
  final VerificationStatusEntity status;
  const _SafetyScoreBreakdown({required this.status});

  @override
  Widget build(BuildContext context) {
    final verificationValue = status.level1Complete
        ? 1.0
        : status.kycStatus == 'pending'
            ? 0.65
            : status.kycStatus == 'draft'
                ? 0.35
                : 0.1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety Score Breakdown',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _ScoreBar(
              label: 'Identity Verification',
              value: verificationValue,
              color: AppColors.success),
          const SizedBox(height: 16),
          _ScoreBar(
              label: 'Meeting Safety',
              value: status.safetyMetricMeetings,
              color: AppColors.blue),
          const SizedBox(height: 16),
          _ScoreBar(
              label: 'Response Rate',
              value: status.safetyMetricResponsiveness,
              color: AppColors.primary),
          const SizedBox(height: 16),
          _ScoreBar(
              label: 'Trust Score',
              value: (status.trustScore / 100).clamp(0.0, 1.0),
              color: AppColors.warning),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ScoreBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text('${(value * 100).toInt()}%',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final VerificationStatusEntity status;
  const _ActionCard({required this.status});

  @override
  Widget build(BuildContext context) {
    // The bottom action button is hidden by default for every status —
    // only a rejected submission gets a "Verify Again" call-to-action here.
    if (status.kycStatus != 'rejected') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next Step',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Review the reason above, then resubmit your documents.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Verify Again',
            onPressed: () => context.go(AppRoutes.verification),
          ),
        ],
      ),
    );
  }
}
