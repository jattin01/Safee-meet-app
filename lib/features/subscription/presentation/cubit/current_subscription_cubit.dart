import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/current_subscription_entity.dart';
import '../../domain/use_cases/get_current_subscription_use_case.dart';
import '../../domain/use_cases/get_subscription_plans_use_case.dart';

enum CurrentSubscriptionStatus { initial, loading, loaded, error }

class CurrentSubscriptionState extends Equatable {
  final CurrentSubscriptionStatus status;
  // Meaningful once status == loaded: null means the account has no
  // subscription row at all, i.e. it's on the implicit free tier.
  final CurrentSubscriptionEntity? subscription;
  // True once we've confirmed the current plan's sortOrder is the highest
  // among all plans in the catalog — i.e. there is nothing left to upgrade
  // to. Always false while subscription is null/free or the plan catalog
  // hasn't been cross-checked yet, so upgrade CTAs default to visible.
  final bool isOnHighestPlan;
  final String? errorMessage;

  const CurrentSubscriptionState({
    this.status = CurrentSubscriptionStatus.initial,
    this.subscription,
    this.isOnHighestPlan = false,
    this.errorMessage,
  });

  bool get hasLoadedOnce => status != CurrentSubscriptionStatus.initial;
  bool get hasSubscription => subscription != null;

  CurrentSubscriptionState copyWith({
    CurrentSubscriptionStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CurrentSubscriptionState(
      status: status ?? this.status,
      subscription: subscription,
      isOnHighestPlan: isOnHighestPlan,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, subscription, isOnHighestPlan, errorMessage];
}

/// A single, app-wide instance of this cubit is registered in get_it as a
/// lazy singleton (see injection_container.dart) so every screen reads the
/// exact same cached subscription state instead of triggering its own
/// GET /v1/subscriptions/current call.
class CurrentSubscriptionCubit extends Cubit<CurrentSubscriptionState> {
  final GetCurrentSubscriptionUseCase _getCurrentSubscription;
  final GetSubscriptionPlansUseCase _getPlans;

  CurrentSubscriptionCubit(this._getCurrentSubscription, this._getPlans)
      : super(const CurrentSubscriptionState());

  Future<void> load({bool forceRefresh = false}) async {
    if (state.status == CurrentSubscriptionStatus.loading) return;

    // Only emit a blocking 'loading' status if we don't already have data.
    // If we already have data, we just fetch silently in the background
    // (Stale-While-Revalidate / Cache-First UX).
    if (state.status != CurrentSubscriptionStatus.loaded) {
      emit(state.copyWith(
        status: CurrentSubscriptionStatus.loading,
        clearError: true,
      ));
    }

    // Started together (Dart futures run eagerly) and awaited separately,
    // since the two calls return differently-typed Eithers.
    final subscriptionFuture = _getCurrentSubscription(forceRefresh: forceRefresh);
    final plansFuture = _getPlans();
    final subscriptionResult = await subscriptionFuture;
    final plansResult = await plansFuture;

    subscriptionResult.fold(
      (failure) => emit(state.copyWith(
        status: CurrentSubscriptionStatus.error,
        errorMessage: failure.message,
      )),
      (subscription) {
        // The plan catalog is only used to decide whether an "Upgrade" CTA
        // still makes sense; if that lookup fails we default to false
        // (show the CTA) rather than block on it or surface a second error.
        final plans = plansResult.getOrElse(() => const []);
        final isHighest = subscription != null &&
            plans.isNotEmpty &&
            subscription.plan.sortOrder >=
                plans.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b);

        emit(CurrentSubscriptionState(
          status: CurrentSubscriptionStatus.loaded,
          subscription: subscription,
          isOnHighestPlan: isHighest,
        ));
      },
    );
  }
}
