import 'package:equatable/equatable.dart';

import 'subscription_plan_entity.dart';

/// Domain model for GET /v1/subscriptions/current — the signed-in user's
/// own active/most-recent subscription record. A `null` instance of this
/// entity (see [CurrentSubscriptionState.subscription]) means the account
/// has no subscription row at all yet, i.e. it is on the implicit free tier.
class CurrentSubscriptionEntity extends Equatable {
  final int id;
  final String subscriptionId;
  final String userId;
  final int planId;

  /// The full plan record embedded in the API response (name, slug,
  /// pricing, features, sortOrder, ...) — reuses the same entity type as
  /// GET /v1/subscriptions/plans since both endpoints shape a plan
  /// identically.
  final SubscriptionPlanEntity plan;

  final double price;
  final String billingCycle;
  final String status;
  final int? trialDays;
  final DateTime? startedAt;
  final DateTime? renewsAt;
  final DateTime? cancelledAt;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  const CurrentSubscriptionEntity({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.planId,
    required this.plan,
    required this.price,
    required this.billingCycle,
    required this.status,
    this.trialDays,
    this.startedAt,
    this.renewsAt,
    this.cancelledAt,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
  });

  bool get isActive => status == 'active';
  bool get isTrialing => status == 'trialing' || status == 'trial';
  bool get isPastDue => status == 'past_due';
  bool get isCancelled => cancelledAt != null || status == 'cancelled';
  bool get isFreePlan => price == 0 && plan.monthlyPrice == 0;

  /// Whether the account currently gets paid-plan perks — true while active
  /// or trialing, even if the user has already scheduled a cancellation
  /// that only takes effect at [renewsAt].
  ///
  /// Also guards against [renewsAt] having already passed: the backend is
  /// expected to flip `status` away from 'active'/'trialing' once a period
  /// lapses, but until that server-side behavior is confirmed/implemented,
  /// this is a client-side safety net so a stale 'trialing'/'active' status
  /// past its own renewal date doesn't keep unlocking paid features
  /// forever. Remove this date check once the backend reliably updates
  /// `status` itself on expiry — `status` should then be the sole source
  /// of truth again.
  bool get hasActiveAccess =>
      (isActive || isTrialing) &&
      (renewsAt == null || renewsAt!.isAfter(DateTime.now()));

  bool get hasTrial => (trialDays ?? plan.trialDays ?? 0) > 0;

  String get planLabel => plan.name;

  /// Capitalises the status string (e.g. "past_due" → "Past due") instead
  /// of hardcoding a fixed set of known statuses.
  String get statusLabel => _titleCase(status.replaceAll('_', ' '));

  String get billingCycleLabel => _titleCase(billingCycle);

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  List<Object?> get props => [
        id,
        subscriptionId,
        userId,
        planId,
        plan,
        price,
        billingCycle,
        status,
        trialDays,
        startedAt,
        renewsAt,
        cancelledAt,
        stripeCustomerId,
        stripeSubscriptionId,
      ];
}
