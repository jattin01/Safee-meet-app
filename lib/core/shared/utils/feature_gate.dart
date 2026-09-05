import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../../../features/subscription/presentation/cubit/current_subscription_cubit.dart';

/// Canonical machine-checkable feature slugs the backend can attach to a
/// plan (`GET /v1/subscriptions/plans` → `features[].slug`). Kept as named
/// constants — not an enum — since a slug is just an opaque string the API
/// owns; referencing [PlanFeature.qrCode] instead of a bare `'qr_code'`
/// literal at each call site catches a typo at compile time instead of
/// letting the gate silently always fail.
class PlanFeature {
  PlanFeature._();

  static const level1Verification = 'level1_verification';
  static const level2Clearance = 'level2_clearance';
  static const backgroundVerification = 'background_verification';
  static const professionalVerification = 'professional_verification';
  static const qrCode = 'qr_code';
  static const basicSafetyTips = 'basic_safety_tips';
  static const communityGuidelines = 'community_guidelines';
  static const trustScore = 'trust_score';
  static const safetyScoreAnalytics = 'safety_score_analytics';
  static const priorityVisibility = 'priority_visibility';
  static const trustedContactAlerts = 'trusted_contact_alerts';
  static const verifiedBadge = 'verified_badge';
  static const premiumBadge = 'premium_badge';
  static const prioritySupport = 'priority_support';
  static const businessListing = 'business_listing';
  static const apiAccess = 'api_access';
  static const dedicatedAccountManager = 'dedicated_account_manager';
  static const customIntegrations = 'custom_integrations';
}

/// Call at the top of a tap handler for any plan-gated feature (mirrors
/// `requireVerification`'s shape). Returns `true` and does nothing if the
/// signed-in user's current plan includes [featureSlug] (see
/// [PlanFeature]); otherwise shows an "Upgrade Required" dialog naming
/// [featureName] and, if the user taps Upgrade, pushes the Subscription
/// screen. Returns `false` so the caller can bail out of whatever action
/// triggered the check.
///
/// Defaults to blocking (returns `false`) while the subscription hasn't
/// loaded yet or the account has no plan row at all — a gated feature
/// should never silently unlock just because we haven't heard back from
/// the server yet.
bool requireFeature(
  BuildContext context,
  String featureSlug,
  String featureName,
) {
  final subscription =
      context.read<CurrentSubscriptionCubit>().state.subscription;
  // hasActiveAccess also rejects an expired/lapsed subscription row (see
  // its doc comment) — without it, a subscription object that's merely
  // non-null (regardless of status or whether renewsAt has already
  // passed) would keep unlocking paid features indefinitely.
  if (subscription != null &&
      subscription.hasActiveAccess &&
      subscription.plan.hasFeature(featureSlug)) {
    return true;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Upgrade Required'),
      content: Text(
        '$featureName isn\'t included in your current plan. Upgrade to unlock it.',
      ),
      actions: [
        TextButton(
          // Guards against the dialog's barrier having already dismissed it
          // (e.g. a stray tap outside right as this button is pressed) —
          // popping an already-inactive route throws Flutter's element-
          // lifecycle assertion instead of just being a harmless no-op.
          onPressed: () {
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () {
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            context.push(AppRoutes.subscription);
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
  return false;
}
