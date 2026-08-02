// Hide the SDK's own VerificationError type — it collides with this
// feature's VerificationBloc state of the same name.
import 'package:didit_sdk/sdk_flutter.dart' hide VerificationError;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/info_banner.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../bloc/verification_bloc.dart';

/// Identity verification entry point — capture itself (ID scan + facial
/// liveness) happens entirely inside Didit's native SDK UI, not in this app.
/// This screen only requests a session token from our backend and launches
/// the SDK with it; the actual approve/decline decision always comes back
/// through our backend (webhook/status poll), never trusted from the SDK
/// result alone.
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _launchingSdk = false;

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _launchDiditSdk(BuildContext context, String sessionToken) async {
    setState(() => _launchingSdk = true);
    try {
      final result = await DiditSdk.startVerification(sessionToken);
      if (!mounted) return;

      switch (result) {
        case VerificationCompleted():
          _showMessage(
              "Verification submitted. We'll update your status once it's reviewed.");
          if (mounted) {
            context
                .read<VerificationBloc>()
                .add(const VerificationStatusRequested());
            context.go(AppRoutes.verificationStatus);
          }
        case VerificationCancelled():
          _showMessage('Verification cancelled.', error: true);
        case VerificationFailed(:final error):
          _showMessage(error.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _launchingSdk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        if (state is VerificationDiditSessionReady) {
          _launchDiditSdk(context, state.session.sessionToken);
        }
        if (state is VerificationError) {
          _showMessage(state.message, error: true);
        }
      },
      builder: (context, state) {
        final isStartingSession = state is VerificationLoading;
        final isBusy = isStartingSession || _launchingSdk;

        return Scaffold(
          backgroundColor: AppColors.lightBg,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DarkScreenHeader(
                  title: 'Identity Verification',
                  titleFontSize: 21,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      24, 32, 24, context.bottomSafePadding(32)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.verified_user_outlined,
                              color: AppColors.blue, size: 30),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Verify Your Identity',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "You'll scan your National ID and take a quick "
                        'selfie to confirm it\'s really you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      const _RequirementRow(
                        icon: Icons.badge_outlined,
                        title: 'National ID',
                        subtitle: "Driver's license, passport, or national ID",
                      ),
                      const SizedBox(height: 14),
                      const _RequirementRow(
                        icon: Icons.camera_alt_outlined,
                        title: 'Selfie',
                        subtitle: 'A quick liveness check to match your ID',
                      ),
                      const SizedBox(height: 20),
                      const InfoBanner(
                        emoji: '🔒',
                        text:
                            'Your documents are processed securely by our verification partner and never stored in this app.',
                        color: AppColors.blue,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: isBusy
                            ? (isStartingSession
                                ? 'Starting...'
                                : 'Verifying...')
                            : 'Start Verification',
                        isLoading: isBusy,
                        onPressed: isBusy
                            ? null
                            : () => context
                                .read<VerificationBloc>()
                                .add(const VerificationDiditSessionRequested()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RequirementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.cardBg, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
