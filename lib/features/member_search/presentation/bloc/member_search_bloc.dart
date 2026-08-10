import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_search_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class MemberSearchEvent extends Equatable {
  const MemberSearchEvent();
  @override
  List<Object?> get props => [];
}

class PINSearchRequested extends MemberSearchEvent {
  final String pin;
  const PINSearchRequested(this.pin);
  @override
  List<Object?> get props => [pin];
}

class QRSearchRequested extends MemberSearchEvent {
  final String qrCode;
  const QRSearchRequested(this.qrCode);
  @override
  List<Object?> get props => [qrCode];
}

class MemberSearchReset extends MemberSearchEvent {
  const MemberSearchReset();
}

/// Loads the previously-searched members list from local storage.
class RecentSearchesRequested extends MemberSearchEvent {
  const RecentSearchesRequested();
}

/// User tapped a member in the "recently searched" list — shows that
/// member's result immediately, without re-hitting the search API.
class RecentMemberSelected extends MemberSearchEvent {
  final MemberEntity member;
  const RecentMemberSelected(this.member);
  @override
  List<Object?> get props => [member];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class MemberSearchState extends Equatable {
  /// Previously-searched members, most recent first. Carried on every state
  /// so the "recently searched" list stays visible regardless of the
  /// current search/result state.
  final List<MemberEntity> recentSearches;

  /// True while the very first `RecentSearchesRequested` fetch is still in
  /// flight — lets the "Recently Searched" section show a spinner instead
  /// of silently rendering nothing until the list (or lack thereof)
  /// arrives. Carried alongside [recentSearches] on every state for the
  /// same reason: a fast search/QR scan can land on Loading/Found before
  /// this resolves, and the section should still reflect it correctly.
  final bool isLoadingRecentSearches;
  const MemberSearchState({
    this.recentSearches = const [],
    this.isLoadingRecentSearches = false,
  });
  @override
  List<Object?> get props => [recentSearches, isLoadingRecentSearches];
}

class MemberSearchInitial extends MemberSearchState {
  const MemberSearchInitial({
    super.recentSearches,
    super.isLoadingRecentSearches,
  });
}

class MemberSearchLoading extends MemberSearchState {
  const MemberSearchLoading({
    super.recentSearches,
    super.isLoadingRecentSearches,
  });
}

class MemberSearchFound extends MemberSearchState {
  final MemberEntity member;
  const MemberSearchFound(
    this.member, {
    super.recentSearches,
    super.isLoadingRecentSearches,
  });
  @override
  List<Object?> get props => [member, ...super.props];
}

class MemberSearchError extends MemberSearchState {
  final String message;
  // True for 403s from the search endpoint, or a 200 response whose body
  // sets `subscription_required: true` (monthly PIN-search limit reached or
  // subscription expired) — both mean "go upgrade your plan", so the UI
  // makes this specific error tappable straight to the plans screen.
  final bool upgradeRequired;
  const MemberSearchError(
    this.message, {
    this.upgradeRequired = false,
    super.recentSearches,
    super.isLoadingRecentSearches,
  });
  @override
  List<Object?> get props => [message, upgradeRequired, ...super.props];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class MemberSearchBloc extends Bloc<MemberSearchEvent, MemberSearchState> {
  final MemberSearchRepository _repository;
  List<MemberEntity> _recent = [];
  bool _recentsLoading = false;

  MemberSearchBloc(this._repository) : super(const MemberSearchInitial()) {
    on<PINSearchRequested>(_onPIN);
    on<QRSearchRequested>(_onQR);
    on<MemberSearchReset>((event, emit) => emit(MemberSearchInitial(
          recentSearches: _recent,
          isLoadingRecentSearches: _recentsLoading,
        )));
    on<RecentSearchesRequested>(_onLoadRecents);
    on<RecentMemberSelected>((event, emit) => emit(MemberSearchFound(
          event.member,
          recentSearches: _recent,
          isLoadingRecentSearches: _recentsLoading,
        )));
  }

  Future<void> _onLoadRecents(
      RecentSearchesRequested event, Emitter<MemberSearchState> emit) async {
    _recentsLoading = true;
    // Only the still-on-the-initial-screen case has a "Recently Searched"
    // loader left to show — if the user already searched (or tapped a
    // recent) by the time this resolves, that screen has moved on.
    if (state is MemberSearchInitial) {
      emit(MemberSearchInitial(
        recentSearches: _recent,
        isLoadingRecentSearches: true,
      ));
    }
    final result = await _repository.getRecentSearches();
    result.fold((_) {}, (list) => _recent = list);
    _recentsLoading = false;
    if (state is MemberSearchInitial) {
      emit(MemberSearchInitial(
        recentSearches: _recent,
        isLoadingRecentSearches: false,
      ));
    }
  }

  Future<void> _onPIN(PINSearchRequested event, Emitter<MemberSearchState> emit) async {
    if (event.pin.length < 6) return;
    emit(MemberSearchLoading(
      recentSearches: _recent,
      isLoadingRecentSearches: _recentsLoading,
    ));
    final result = await _repository.searchByPIN(event.pin);
    await _emitResult(result, emit);
  }

  Future<void> _onQR(QRSearchRequested event, Emitter<MemberSearchState> emit) async {
    emit(MemberSearchLoading(
      recentSearches: _recent,
      isLoadingRecentSearches: _recentsLoading,
    ));
    final result = await _repository.searchByQR(event.qrCode);
    await _emitResult(result, emit);
  }

  Future<void> _emitResult(Either<Failure, MemberEntity> result,
      Emitter<MemberSearchState> emit) async {
    await result.fold(
      (f) async => emit(MemberSearchError(
        f.message,
        upgradeRequired: f is ServerFailure &&
            (f.statusCode == 403 || f.code == 'SUBSCRIPTION_REQUIRED'),
        recentSearches: _recent,
        isLoadingRecentSearches: _recentsLoading,
      )),
      (m) async {
        final refreshed = await _repository.getRecentSearches();
        refreshed.fold((_) {}, (list) => _recent = list);
        emit(MemberSearchFound(
          m,
          recentSearches: _recent,
          isLoadingRecentSearches: _recentsLoading,
        ));
      },
    );
  }
}
