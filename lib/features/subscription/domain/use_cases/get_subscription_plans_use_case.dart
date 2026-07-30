import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/subscription_plan_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionPlansUseCase {
  final SubscriptionRepository _repository;
  GetSubscriptionPlansUseCase(this._repository);

  Future<Either<Failure, List<SubscriptionPlanEntity>>> call() =>
      _repository.getPlans();
}
