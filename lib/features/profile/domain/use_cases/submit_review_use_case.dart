import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../entities/submitted_review_entity.dart';

class SubmitReviewUseCase {
  final ProfileRepository _repository;
  SubmitReviewUseCase(this._repository);

  Future<Either<Failure, SubmittedReviewEntity>> call({
    required String meetingId,
    required int userId,
    required int rating,
    String? comment,
    required bool punctual,
    required bool trustworthy,
    required bool responsive,
  }) =>
      _repository.submitReview(
        meetingId: meetingId,
        userId: userId,
        rating: rating,
        comment: comment,
        punctual: punctual,
        trustworthy: trustworthy,
        responsive: responsive,
      );
}
