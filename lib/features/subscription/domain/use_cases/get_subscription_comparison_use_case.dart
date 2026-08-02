import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/subscription_comparison_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionComparisonUseCase {
  final SubscriptionRepository _repository;
  GetSubscriptionComparisonUseCase(this._repository);

  Future<Either<Failure, SubscriptionComparisonEntity>> call({
    bool forceRefresh = false,
  }) =>
      _repository.getComparison(forceRefresh: forceRefresh);
}
