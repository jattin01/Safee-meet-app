import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/current_subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
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
  // Full plan catalog — populated after /plans is loaded.
  final List<SubscriptionPlanEntity> availablePlans;
  // True when the backend confirmed 404 (no active subscription at all).
  // Used by UI to show an Upgrade CTA instead of a plan name.
  final bool noActiveSubscription;

  const CurrentSubscriptionState({
    this.status = CurrentSubscriptionStatus.initial,
    this.subscription,
    this.isOnHighestPlan = false,
    this.errorMessage,
    this.availablePlans = const [],
    this.noActiveSubscription = false,
  });

  bool get hasLoadedOnce => status != CurrentSubscriptionStatus.initial;
  bool get hasSubscription => subscription != null;

  // Returns the lowest-sort-order plan name from the catalog.
  String? get lowestPlanName {
    if (availablePlans.isEmpty) return null;
    final sorted = [...availablePlans]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.first.name;
  }

  CurrentSubscriptionState copyWith({
    CurrentSubscriptionStatus? status,
    String? errorMessage,
    bool clearError = false,
    List<SubscriptionPlanEntity>? availablePlans,
    bool? noActiveSubscription,
  }) {
    return CurrentSubscriptionState(
      status: status ?? this.status,
      subscription: subscription,
      isOnHighestPlan: isOnHighestPlan,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      availablePlans: availablePlans ?? this.availablePlans,
      noActiveSubscription: noActiveSubscription ?? this.noActiveSubscription,
    );
  }

  @override
  List<Object?> get props =>
      [status, subscription, isOnHighestPlan, errorMessage, availablePlans, noActiveSubscription];
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

  // Coalesces concurrent load() calls into a single in-flight round trip.
  // The old guard (`if (state.status == loading) return`) wasn't enough:
  // the cache-first step below flips status to `loaded` *before* the
  // network fetch finishes, so a second caller landing in that window
  // (e.g. the router guard's load() racing the shell route's own
  // ..load()) saw `loaded`/not-`loading` and fired a second, fully
  // redundant GET /v1/subscriptions/current + /plans — this is why those
  // showed up twice in a row during the post-login warm-up burst.
  Future<void>? _inFlight;

  Future<void> load({bool forceRefresh = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    // The router guard and shell can both call load() on every navigation.
    // Once this app-wide cubit has data, those normal calls must use it;
    // only an explicit refresh is allowed to make another network round trip.
    if (!forceRefresh && state.status == CurrentSubscriptionStatus.loaded) {
      return Future.value();
    }

    final future = _load(forceRefresh: forceRefresh);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final hasExistingData = state.status == CurrentSubscriptionStatus.loaded;

    if (!hasExistingData) {
      emit(state.copyWith(
        status: CurrentSubscriptionStatus.loading,
        clearError: true,
      ));

      // 1. Stale-While-Revalidate: Try to load from local cache instantly
      if (!forceRefresh) {
        final cacheResult = await _getCurrentSubscription(forceRefresh: false);
        cacheResult.fold(
          (_) {}, // Ignore cache errors
          (subscription) {
            // Emit the cached subscription to unblock the UI instantly.
            // We'll update it properly with isOnHighestPlan in step 2.
            emit(CurrentSubscriptionState(
              status: CurrentSubscriptionStatus.loaded,
              subscription: subscription,
              isOnHighestPlan: state.isOnHighestPlan,
            ));
          },
        );
      }
    }

    // 2. Always fetch fresh data from network in the background.
    // We pass forceRefresh: true to bypass the cache in the repository.
    final subscriptionFuture = _getCurrentSubscription(forceRefresh: true);
    final plansFuture = _getPlans();
    
    final subscriptionResult = await subscriptionFuture;
    final plansResult = await plansFuture;

    subscriptionResult.fold(
      (failure) {
        // Only surface the error if we don't already have perfectly good cached data
        if (state.status != CurrentSubscriptionStatus.loaded) {
          emit(state.copyWith(
            status: CurrentSubscriptionStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
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
          availablePlans: plans,
          // noActiveSubscription is true when backend confirmed null (404)
          noActiveSubscription: subscription == null,
        ));
      },
    );
  }

  /// Clears cached subscription state — call on logout. This cubit is an
  /// app-lifetime DI singleton (see injection_container.dart), so without
  /// this a different user logging in later in the same app session would
  /// briefly see the previous user's cached plan.
  void reset() => emit(const CurrentSubscriptionState());
}
