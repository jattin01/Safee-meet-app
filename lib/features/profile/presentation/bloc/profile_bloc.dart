import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class ReviewsLoadRequested extends ProfileEvent {
  final String? filter;
  const ReviewsLoadRequested({this.filter});
  @override
  List<Object?> get props => [filter];
}

class ReviewMarkedHelpful extends ProfileEvent {
  final String reviewId;
  const ReviewMarkedHelpful(this.reviewId);
  @override
  List<Object?> get props => [reviewId];
}

/// Dispatched on logout to clear the cached profile/reviews — see
/// [ProfileBloc.reset].
class ProfileResetRequested extends ProfileEvent {
  const ProfileResetRequested();
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<ReviewEntity> reviews;
  final bool reviewsLoading;
  final String? reviewFilter;
  final int timestamp;

  const ProfileLoaded({
    required this.profile,
    this.reviews = const [],
    this.reviewsLoading = false,
    this.reviewFilter,
    this.timestamp = 0,
  });

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    List<ReviewEntity>? reviews,
    bool? reviewsLoading,
    String? reviewFilter,
    int? timestamp,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      reviews: reviews ?? this.reviews,
      reviewsLoading: reviewsLoading ?? this.reviewsLoading,
      reviewFilter: reviewFilter ?? this.reviewFilter,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [profile, reviews, reviewsLoading, reviewFilter, timestamp];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ReviewsLoadRequested>(_onReviews);
    on<ReviewMarkedHelpful>(_onHelpful);
    on<ProfileResetRequested>(_onReset);
  }

  Future<void> _onLoad(ProfileLoadRequested _, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileLoading());
    }
    
    final result = await _repository.getProfile();
    result.fold(
      (f) {
        // A transient refresh failure shouldn't wipe out a profile we
        // already loaded successfully — that would blank the whole screen
        // (including an already-valid safeePIN/QR code) over a flaky
        // retry. Only surface ProfileError when there was never a good
        // profile to fall back on; otherwise keep showing the last-known-
        // good one. Bump the timestamp so this is still a distinct value
        // that reaches the stream (pull-to-refresh awaits it for a
        // terminal state), even though `profile` itself is unchanged.
        if (currentState is ProfileLoaded) {
          emit(currentState.copyWith(
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
        } else {
          emit(ProfileError(f.message));
        }
      },
      (p) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        if (currentState is ProfileLoaded) {
          emit(currentState.copyWith(profile: p, timestamp: ts));
        } else {
          emit(ProfileLoaded(profile: p, timestamp: ts));
        }
      },
    );
  }

  Future<void> _onReviews(ReviewsLoadRequested event, Emitter<ProfileState> emit) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    emit(current.copyWith(reviewsLoading: true, reviewFilter: event.filter));
    final result = await _repository.getReviews(filter: event.filter);
    result.fold(
      // A reviews-fetch failure is unrelated to the profile itself — just
      // stop the reviews spinner instead of downgrading to ProfileError,
      // which would otherwise blank out the whole profile screen (name,
      // avatar, and the safeePIN/QR code) over what's really just the
      // reviews list failing to load.
      (f) => emit(current.copyWith(reviewsLoading: false)),
      (reviews) => emit(current.copyWith(reviews: reviews, reviewsLoading: false)),
    );
  }

  Future<void> _onHelpful(ReviewMarkedHelpful event, Emitter<ProfileState> emit) async {
    await _repository.markReviewHelpful(event.reviewId);
    if (state is ProfileLoaded) {
      add(ReviewsLoadRequested(filter: (state as ProfileLoaded).reviewFilter));
    }
  }

  void _onReset(ProfileResetRequested _, Emitter<ProfileState> emit) =>
      emit(const ProfileInitial());

  /// Clears the cached profile/reviews — call on logout. This bloc is an
  /// app-lifetime DI singleton (see injection_container.dart) that
  /// otherwise keeps whichever user's data it last loaded in memory, so
  /// without this a different user logging in later in the same app
  /// session would briefly see the previous user's cached profile.
  void reset() => add(const ProfileResetRequested());
}
