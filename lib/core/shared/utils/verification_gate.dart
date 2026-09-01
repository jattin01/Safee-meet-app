import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../../../features/profile/presentation/cubit/current_user_cubit.dart';
import 'package:flutter/foundation.dart';
import '../widgets/app_snackbar.dart';

/// Call at the top of a tap handler for any verification-gated feature
/// (Safee-PIN search, create/join/manage meetings, meeting history, SOS,
/// chat, PIN sharing, reviews). Returns `true` and does nothing if the
/// signed-in user is verified, so the caller can proceed as normal.
///
/// If unverified, shows the standard "Verification Required" snackbar, then
/// pushes the Upload Verification (start) screen only if nothing has ever
/// been submitted (`verificationStatus == 'not_submitted'`) — every other
/// status (unverified/pending/rejected/etc.) goes to the Verification
/// Status screen instead. Returns `false` so the caller can bail out of
/// whatever action triggered the check.
///
/// This is the UX-friendly layer (visible feedback before navigating) that
/// sits in front of AppRouter's own redirect guard, which silently blocks
/// the same restricted routes as a backstop for entry points that don't go
/// through a tap handler (deep links, notification taps, back navigation).
bool requireVerification(BuildContext context) {
  final cubit = context.read<CurrentUserCubit>();
  if (cubit.isVerified) return true;

  AppSnackbar.info(
    context,
    'Complete your verification to access this feature.',
    title: 'Verification Required',
    duration: const Duration(seconds: 1),
  );

  final verificationStatus = cubit.state.profile?.verificationStatus;
  context.push(
    verificationStatus == 'not_submitted'
        ? AppRoutes.verification
        : AppRoutes.verificationStatus,
  );
  return false;
}

/// Fetches the caller's live verification status and routes to the right
/// screen: the Upload Verification (start) flow only when nothing has ever
/// been submitted; the Verification Status page for every other case.
void openVerificationScreen(BuildContext context) {
  final cubit = context.read<CurrentUserCubit>();
  final verificationStatus = cubit.state.profile?.verificationStatus;
  
  context.push(
    verificationStatus == 'not_submitted' || verificationStatus == 'none'
        ? AppRoutes.verification
        : AppRoutes.verificationStatus,
  );
}
