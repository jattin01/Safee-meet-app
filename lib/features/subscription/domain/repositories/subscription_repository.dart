import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/current_subscription_entity.dart';
import '../entities/subscription_checkout_entity.dart';
import '../entities/subscription_comparison_entity.dart';
import '../entities/subscription_plan_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans();

  Future<Either<Failure, SubscriptionCheckoutEntity>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  });

  /// [forceRefresh] bypasses the in-memory cache and re-fetches from the API.
  Future<Either<Failure, SubscriptionComparisonEntity>> getComparison({
    bool forceRefresh = false,
  });

  /// A `null` right-hand value means the account has no subscription row at
  /// all (implicit free tier) — that is a successful result, not a failure.
  /// [forceRefresh] bypasses both the in-memory and on-disk cache.
  Future<Either<Failure, CurrentSubscriptionEntity?>> getCurrentSubscription({
    bool forceRefresh = false,
  });
}
