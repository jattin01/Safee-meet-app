import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../entities/reviews_summary_entity.dart';

class GetReviewsListUseCase {
  final ProfileRepository _repository;
  GetReviewsListUseCase(this._repository);

  Future<Either<Failure, ReviewsSummaryEntity>> call({
    int? stars,
    String? category,
    required int page,
  }) =>
      _repository.getReviewsList(stars: stars, category: category, page: page);
}
