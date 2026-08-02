import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/current_subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetCurrentSubscriptionUseCase {
  final SubscriptionRepository _repository;
  GetCurrentSubscriptionUseCase(this._repository);

  Future<Either<Failure, CurrentSubscriptionEntity?>> call({
    bool forceRefresh = false,
  }) =>
      _repository.getCurrentSubscription(forceRefresh: forceRefresh);
}
