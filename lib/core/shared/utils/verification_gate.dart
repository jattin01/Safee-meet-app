import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../dependency_injection/injection_container.dart';
import '../../routes/app_routes.dart';
import '../../../features/profile/presentation/cubit/current_user_cubit.dart';
import '../../../features/verification/domain/repositories/verification_repository.dart';
import '../widgets/app_snackbar.dart';

/// Call at the top of a tap handler for any verification-gated feature
/// (Safee-PIN search, create/join/manage meetings, meeting history, SOS,
/// chat, PIN sharing, reviews). Returns `true` and does nothing if the
/// signed-in user is verified, so the caller can proceed as normal.
///
/// If unverified, shows the standard "Verification Required" snackbar,
/// pushes the Verification screen, and returns `false` so the caller can
/// bail out of whatever action triggered the check.
///
/// This is the UX-friendly layer (visible feedback before navigating) that
/// sits in front of AppRouter's own redirect guard, which silently blocks
/// the same restricted routes as a backstop for entry points that don't go
/// through a tap handler (deep links, notification taps, back navigation).
bool requireVerification(BuildContext context) {
  if (context.read<CurrentUserCubit>().isVerified) return true;

  AppSnackbar.info(
    context,
    'Complete your verification to access this feature..',
    title: 'Verification Required',
    duration: const Duration(seconds: 1),
  );
  context.push(AppRoutes.verification);
  return false;
}

/// Fetches the caller's live verification status and routes to the right
/// screen: the Verification Status page only when it's actually `approved`;
/// the Upload Verification flow for every other case — not submitted,
/// pending, rejected, or the status lookup itself failing — so the user
/// always lands somewhere they can (re)submit rather than on a status page
/// with nothing to show.
Future<void> openVerificationScreen(BuildContext context) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final result = await sl<VerificationRepository>().getVerificationStatus();

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  final isApproved = result.fold(
    (_) => false,
    (status) => status.kycStatus == 'approved',
  );

  if (!context.mounted) return;
  context.push(
    isApproved ? AppRoutes.verificationStatus : AppRoutes.verification,
  );
}
