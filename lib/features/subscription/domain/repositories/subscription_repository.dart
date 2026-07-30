import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/subscription_checkout_entity.dart';
import '../entities/subscription_plan_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPlanEntity>>> getPlans();

  Future<Either<Failure, SubscriptionCheckoutEntity>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  });
}
