import '../../domain/entities/current_subscription_entity.dart';
import 'subscription_plan_model.dart';

class CurrentSubscriptionModel {
  final int id;
  final String subscriptionId;
  final String userId;
  final int planId;
  final SubscriptionPlanModel plan;
  final double price;
  final String billingCycle;
  final String status;
  final int? trialDays;
  final DateTime? startedAt;
  final DateTime? renewsAt;
  final DateTime? cancelledAt;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  const CurrentSubscriptionModel({
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

  factory CurrentSubscriptionModel.fromJson(Map<String, dynamic> json) =>
      CurrentSubscriptionModel(
        id: (json['id'] as num).toInt(),
        subscriptionId: json['subscription_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        planId: (json['plan_id'] as num?)?.toInt() ?? 0,
        // Defensively normalised: fresh from Dio this is already
        // Map<String, dynamic>, but a value round-tripped through the Hive
        // cache can come back as Map<dynamic, dynamic>.
        plan: SubscriptionPlanModel.fromJson(
          json['plan'] is Map
              ? Map<String, dynamic>.from(json['plan'] as Map)
              : const {},
        ),
        price: _toDouble(json['price']),
        billingCycle: json['billing_cycle'] as String? ?? 'monthly',
        status: json['status'] as String? ?? 'inactive',
        trialDays: (json['trial_days'] as num?)?.toInt(),
        startedAt: _toDate(json['started_at']),
        renewsAt: _toDate(json['renews_at']),
        cancelledAt: _toDate(json['cancelled_at']),
        stripeCustomerId: json['stripe_customer_id'] as String?,
        stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscription_id': subscriptionId,
        'user_id': userId,
        'plan_id': planId,
        'plan': plan.toJson(),
        'price': price,
        'billing_cycle': billingCycle,
        'status': status,
        'trial_days': trialDays,
        'started_at': startedAt?.toIso8601String(),
        'renews_at': renewsAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
      };

  CurrentSubscriptionEntity toEntity() => CurrentSubscriptionEntity(
        id: id,
        subscriptionId: subscriptionId,
        userId: userId,
        planId: planId,
        plan: plan.toEntity(),
        price: price,
        billingCycle: billingCycle,
        status: status,
        trialDays: trialDays,
        startedAt: startedAt,
        renewsAt: renewsAt,
        cancelledAt: cancelledAt,
        stripeCustomerId: stripeCustomerId,
        stripeSubscriptionId: stripeSubscriptionId,
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    return v is String ? double.parse(v) : (v as num).toDouble();
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v as String);
  }
}
