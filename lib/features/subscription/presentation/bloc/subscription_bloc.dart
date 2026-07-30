import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/use_cases/get_subscription_plans_use_case.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetSubscriptionPlansUseCase _getPlans;
  final SubscriptionRepository _repository;
  final StripePaymentService _stripePaymentService;

  SubscriptionBloc(this._getPlans, this._repository, this._stripePaymentService)
      : super(const SubscriptionInitial()) {
    on<SubscriptionPlansRequested>(_onPlansRequested);
    on<SubscribeRequested>(_onSubscribeRequested);
  }

  Future<void> _onPlansRequested(
    SubscriptionPlansRequested _,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionLoading());
    final result = await _getPlans();
    result.fold(
      (f) => emit(SubscriptionError(f.message)),
      (plans) => emit(SubscriptionLoaded(plans)),
    );
  }

  Future<void> _onSubscribeRequested(
    SubscribeRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = state;
    if (current is! SubscriptionLoaded) return;

    emit(SubscriptionLoaded(current.plans, checkoutStatus: CheckoutStatus.processing));

    final result = await _repository.subscribe(
      planSlug: event.planSlug,
      billingCycle: event.billingCycle,
      stripePaymentMethodId: event.stripeTestPaymentMethodId,
    );

    await result.fold(
      (failure) async {
        emit(SubscriptionLoaded(
          current.plans,
          checkoutErrorMessage: failure.message,
        ));
      },
      (checkout) async {
        debugPrint(
          '[Subscribe] subscriptionId=${checkout.subscriptionId} '
          'status=${checkout.status} '
          'hasClientSecret=${checkout.paymentIntentClientSecret != null} '
          'requiresConfirmation=${checkout.requiresPaymentConfirmation}',
        );

        if (!checkout.requiresPaymentConfirmation) {
          emit(SubscriptionLoaded(current.plans, checkoutStatus: CheckoutStatus.success));
          return;
        }

        debugPrint('[Subscribe] Presenting Stripe checkout…');
        final checkoutResult = await _stripePaymentService.presentCheckout(
          clientSecret: checkout.paymentIntentClientSecret!,
          merchantDisplayName: AppConstants.appName,
        );

        checkoutResult.fold(
          (failure) {
            debugPrint('[Subscribe] Stripe checkout FAILED: ${failure.message}');
            emit(SubscriptionLoaded(
              current.plans,
              checkoutErrorMessage: failure.message,
            ));
          },
          (outcome) {
            if (outcome == PaymentSheetOutcome.canceled) {
              debugPrint('[Subscribe] Stripe checkout canceled by user');
              // Back to idle, no error — the user simply backed out.
              emit(SubscriptionLoaded(current.plans));
              return;
            }
            debugPrint('[Subscribe] Stripe checkout SUCCEEDED');
            emit(SubscriptionLoaded(current.plans, checkoutStatus: CheckoutStatus.success));
          },
        );
      },
    );
  }
}
