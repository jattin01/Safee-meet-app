import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_plan_entity.dart';

enum CheckoutStatus { idle, processing, success }

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionPlanEntity> plans;
  final CheckoutStatus checkoutStatus;
  // Set only on the state right after a failed checkout attempt, so the UI
  // can show it once via a listener; cleared on the next attempt/success.
  final String? checkoutErrorMessage;

  const SubscriptionLoaded(
    this.plans, {
    this.checkoutStatus = CheckoutStatus.idle,
    this.checkoutErrorMessage,
  });

  @override
  List<Object?> get props => [plans, checkoutStatus, checkoutErrorMessage];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}
