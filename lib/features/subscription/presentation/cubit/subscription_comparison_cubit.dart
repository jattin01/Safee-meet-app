import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/subscription_comparison_entity.dart';
import '../../domain/use_cases/get_subscription_comparison_use_case.dart';

enum ComparisonStatus { initial, loading, loaded, error }

class SubscriptionComparisonState extends Equatable {
  final ComparisonStatus status;
  final SubscriptionComparisonEntity? comparison;
  final String? errorMessage;

  const SubscriptionComparisonState({
    this.status = ComparisonStatus.initial,
    this.comparison,
    this.errorMessage,
  });

  SubscriptionComparisonState copyWith({
    ComparisonStatus? status,
    SubscriptionComparisonEntity? comparison,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubscriptionComparisonState(
      status: status ?? this.status,
      comparison: comparison ?? this.comparison,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, comparison, errorMessage];
}

class SubscriptionComparisonCubit extends Cubit<SubscriptionComparisonState> {
  final GetSubscriptionComparisonUseCase _getComparison;

  SubscriptionComparisonCubit(this._getComparison)
      : super(const SubscriptionComparisonState());

  Future<void> load({bool forceRefresh = false}) async {
    if (state.status == ComparisonStatus.loading) return;

    emit(state.copyWith(status: ComparisonStatus.loading, clearError: true));

    final result = await _getComparison(forceRefresh: forceRefresh);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ComparisonStatus.error,
        errorMessage: failure.message,
      )),
      (comparison) => emit(SubscriptionComparisonState(
        status: ComparisonStatus.loaded,
        comparison: comparison,
      )),
    );
  }
}
