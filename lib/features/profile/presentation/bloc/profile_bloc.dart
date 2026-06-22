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

  const ProfileLoaded({
    required this.profile,
    this.reviews = const [],
    this.reviewsLoading = false,
    this.reviewFilter,
  });

  ProfileLoaded copyWith({
    ProfileEntity? profile,
    List<ReviewEntity>? reviews,
    bool? reviewsLoading,
    String? reviewFilter,
  }) =>
      ProfileLoaded(
        profile: profile ?? this.profile,
        reviews: reviews ?? this.reviews,
        reviewsLoading: reviewsLoading ?? this.reviewsLoading,
        reviewFilter: reviewFilter ?? this.reviewFilter,
      );

  @override
  List<Object?> get props => [profile, reviews, reviewsLoading, reviewFilter];
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
  }

  Future<void> _onLoad(ProfileLoadRequested _, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await _repository.getProfile();
    result.fold(
      (f) => emit(ProfileError(f.message)),
      (p) => emit(ProfileLoaded(profile: p)),
    );
  }

  Future<void> _onReviews(ReviewsLoadRequested event, Emitter<ProfileState> emit) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    emit(current.copyWith(reviewsLoading: true, reviewFilter: event.filter));
    final result = await _repository.getReviews(filter: event.filter);
    result.fold(
      (f) => emit(ProfileError(f.message)),
      (reviews) => emit(current.copyWith(reviews: reviews, reviewsLoading: false)),
    );
  }

  Future<void> _onHelpful(ReviewMarkedHelpful event, Emitter<ProfileState> emit) async {
    await _repository.markReviewHelpful(event.reviewId);
    if (state is ProfileLoaded) {
      add(ReviewsLoadRequested(filter: (state as ProfileLoaded).reviewFilter));
    }
  }
}
