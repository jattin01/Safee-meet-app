import 'dart:async';
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

  // Only while unverified — polls /v1/auth/me every few seconds so
  // verification-gated features unlock across the whole app the moment
  // review completes, without the user logging out, restarting, or manually
  // refreshing. Stops itself once verified.
  static const _pollInterval = Duration(seconds: 8);
  Timer? _pollTimer;

  CurrentUserCubit(this._repository) : super(const CurrentUserState());

  bool get isVerified =>
      state.profile != null && state.profile!.verificationLevel != 'none';

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
    _scheduleNextPollIfNeeded();
  }

  void _scheduleNextPollIfNeeded() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!isVerified && !isClosed) {
      _pollTimer = Timer(_pollInterval, () => load(forceRefresh: true));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
