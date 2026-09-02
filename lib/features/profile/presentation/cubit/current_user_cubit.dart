import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../messaging/domain/use_cases/sync_user_profile_use_case.dart';
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
  final SyncUserProfileUseCase _syncUserProfile;

  // Only while unverified — polls /v1/auth/me every few seconds so
  // verification-gated features unlock across the whole app the moment
  // review completes, without the user logging out, restarting, or manually
  // refreshing. Stops itself once verified.
  static const _pollInterval = Duration(seconds: 8);
  Timer? _pollTimer;

  // Tracks the last (name, avatarUrl) pair we pushed to the messaging
  // feature's users/{uid} doc, so the 8s re-verification poll above doesn't
  // fire a redundant Firestore write every tick — only an actual change
  // (or the very first load) triggers a new sync.
  (String, String?)? _lastSyncedIdentity;

  CurrentUserCubit(this._repository, this._syncUserProfile)
      : super(const CurrentUserState());

  bool get isVerified =>
      state.profile != null && state.profile!.verificationLevel != 'none';

  // Coalesces concurrent load() calls into a single in-flight GET
  // /v1/auth/me — main.dart's app-root load(), the router guard's
  // verification check, and the shell route's own ..load() can all land
  // around the same login→home transition; without this they'd each fire
  // an independent request instead of sharing one.
  Future<void>? _inFlight;

  Future<void> load({bool forceRefresh = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _load(forceRefresh: forceRefresh);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _load({bool forceRefresh = false}) async {
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
    _syncIdentityIfChanged();
    _scheduleNextPollIfNeeded();
  }

  void setProfile(ProfileEntity profile) {
    emit(state.copyWith(
      status: CurrentUserStatus.loaded,
      profile: profile,
      clearError: true,
    ));
    _syncIdentityIfChanged();
    _scheduleNextPollIfNeeded();
  }

  // Fire-and-forget: pushes the current name/avatar to the messaging
  // feature's users/{uid} doc whenever it actually changed since the last
  // sync (first load, a real profile edit, or a display-name change) —
  // never on every 8s re-verification poll tick when nothing changed. Must
  // never surface a failure here or block/affect this cubit's own state;
  // messaging already treats this collection as best-effort (see
  // PresenceService for the same pattern).
  void _syncIdentityIfChanged() {
    final profile = state.profile;
    if (profile == null) return;
    final identity = (profile.name, profile.avatarUrl);
    if (identity == _lastSyncedIdentity) return;
    _lastSyncedIdentity = identity;
    _syncUserProfile(name: profile.name, avatarUrl: profile.avatarUrl);
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
