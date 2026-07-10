import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';

enum CurrentUserStatus { initial, loading, loaded, refreshing, error }

class CurrentUserState extends Equatable {
  final CurrentUserStatus status;
  final ProfileEntity? profile;
  final String? errorMessage;

  const CurrentUserState({
    this.status = CurrentUserStatus.initial,
    this.profile,
    this.errorMessage,
  });

  bool get hasProfile => profile != null;

  CurrentUserState copyWith({
    CurrentUserStatus? status,
    ProfileEntity? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CurrentUserState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

class CurrentUserCubit extends Cubit<CurrentUserState> {
  final ProfileRepository _repository;

  CurrentUserCubit(this._repository) : super(const CurrentUserState());

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (state.status == CurrentUserStatus.loading ||
            state.status == CurrentUserStatus.refreshing)) {
      return;
    }

    emit(
      state.hasProfile
          ? state.copyWith(
              status: CurrentUserStatus.refreshing,
              clearError: true,
            )
          : state.copyWith(
              status: CurrentUserStatus.loading,
              clearError: true,
            ),
    );

    final result = await _repository.getProfile();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CurrentUserStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        state.copyWith(
          status: CurrentUserStatus.loaded,
          profile: profile,
          clearError: true,
        ),
      ),
    );
  }
}
