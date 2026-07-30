import 'package:equatable/equatable.dart';

/// Result of POST /v1/subscriptions/subscribe — a subscription row plus,
/// for paid plans, the Stripe PaymentIntent client secret the app must
/// confirm via the Stripe SDK before the subscription becomes chargeable.
class SubscriptionCheckoutEntity extends Equatable {
  final String subscriptionId;
  final String status; // trial | active | incomplete
  final String? paymentIntentClientSecret;

  const SubscriptionCheckoutEntity({
    required this.subscriptionId,
    required this.status,
    this.paymentIntentClientSecret,
  });

  /// Free/trial plans (or a plan that Stripe activated instantly) need no
  /// further client-side payment confirmation.
  bool get requiresPaymentConfirmation =>
      paymentIntentClientSecret != null && status != 'active' && status != 'trial';

  @override
  List<Object?> get props => [subscriptionId, status, paymentIntentClientSecret];
}
