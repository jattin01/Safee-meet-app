import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/submit_review_use_case.dart';

enum SubmitReviewStatus { idle, submitting, success, error }

class SubmitReviewState extends Equatable {
  final SubmitReviewStatus status;
  final String? errorMessage;

  const SubmitReviewState({
    this.status = SubmitReviewStatus.idle,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, errorMessage];
}

class SubmitReviewCubit extends Cubit<SubmitReviewState> {
  final SubmitReviewUseCase _submitReview;
  SubmitReviewCubit(this._submitReview) : super(const SubmitReviewState());

  Future<void> submit({
    required String meetingId,
    required int userId,
    required int rating,
    String? comment,
    required bool punctual,
    required bool trustworthy,
    required bool responsive,
  }) async {
    // Re-entrancy guard: ignores a second tap while one submission is
    // already in flight, on top of the Submit button disabling itself.
    if (state.status == SubmitReviewStatus.submitting) return;

    emit(const SubmitReviewState(status: SubmitReviewStatus.submitting));

    final result = await _submitReview(
      meetingId: meetingId,
      userId: userId,
      rating: rating,
      comment: comment,
      punctual: punctual,
      trustworthy: trustworthy,
      responsive: responsive,
    );

    result.fold(
      (failure) => emit(SubmitReviewState(
        status: SubmitReviewStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(const SubmitReviewState(status: SubmitReviewStatus.success)),
    );
  }
}
