import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class SubscriptionPlansRequested extends SubscriptionEvent {
  const SubscriptionPlansRequested();
}

/// [stripeTestPaymentMethodId] is one of Stripe's predefined TEST-mode
/// payment method tokens (e.g. 'pm_card_visa') — null for free/trial plans,
/// which the backend accepts without a payment method.
class SubscribeRequested extends SubscriptionEvent {
  final String planSlug;
  final String billingCycle;
  final String? stripeTestPaymentMethodId;

  const SubscribeRequested({
    required this.planSlug,
    required this.billingCycle,
    this.stripeTestPaymentMethodId,
  });

  @override
  List<Object?> get props => [planSlug, billingCycle, stripeTestPaymentMethodId];
}
