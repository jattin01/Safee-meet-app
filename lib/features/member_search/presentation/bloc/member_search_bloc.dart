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
  const MemberSearchState({this.recentSearches = const []});
  @override
  List<Object?> get props => [recentSearches];
}

class MemberSearchInitial extends MemberSearchState {
  const MemberSearchInitial({super.recentSearches});
}

class MemberSearchLoading extends MemberSearchState {
  const MemberSearchLoading({super.recentSearches});
}

class MemberSearchFound extends MemberSearchState {
  final MemberEntity member;
  const MemberSearchFound(this.member, {super.recentSearches});
  @override
  List<Object?> get props => [member, ...super.props];
}

class MemberSearchError extends MemberSearchState {
  final String message;
  // True for 403s from the search endpoint (monthly PIN-search limit reached
  // or subscription expired) — both mean "go upgrade your plan", so the UI
  // makes this specific error tappable straight to the plans screen.
  final bool upgradeRequired;
  const MemberSearchError(
    this.message, {
    this.upgradeRequired = false,
    super.recentSearches,
  });
  @override
  List<Object?> get props => [message, upgradeRequired, ...super.props];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class MemberSearchBloc extends Bloc<MemberSearchEvent, MemberSearchState> {
  final MemberSearchRepository _repository;
  List<MemberEntity> _recent = [];

  MemberSearchBloc(this._repository) : super(const MemberSearchInitial()) {
    on<PINSearchRequested>(_onPIN);
    on<QRSearchRequested>(_onQR);
    on<MemberSearchReset>(
        (event, emit) => emit(MemberSearchInitial(recentSearches: _recent)));
    on<RecentSearchesRequested>(_onLoadRecents);
    on<RecentMemberSelected>((event, emit) =>
        emit(MemberSearchFound(event.member, recentSearches: _recent)));
  }

  Future<void> _onLoadRecents(
      RecentSearchesRequested event, Emitter<MemberSearchState> emit) async {
    final result = await _repository.getRecentSearches();
    result.fold((_) {}, (list) => _recent = list);
    if (state is MemberSearchInitial) {
      emit(MemberSearchInitial(recentSearches: _recent));
    }
  }

  Future<void> _onPIN(PINSearchRequested event, Emitter<MemberSearchState> emit) async {
    if (event.pin.length < 6) return;
    emit(MemberSearchLoading(recentSearches: _recent));
    final result = await _repository.searchByPIN(event.pin);
    await _emitResult(result, emit);
  }

  Future<void> _onQR(QRSearchRequested event, Emitter<MemberSearchState> emit) async {
    emit(MemberSearchLoading(recentSearches: _recent));
    final result = await _repository.searchByQR(event.qrCode);
    await _emitResult(result, emit);
  }

  Future<void> _emitResult(Either<Failure, MemberEntity> result,
      Emitter<MemberSearchState> emit) async {
    await result.fold(
      (f) async => emit(MemberSearchError(
        f.message,
        upgradeRequired: f is ServerFailure && f.statusCode == 403,
        recentSearches: _recent,
      )),
      (m) async {
        final refreshed = await _repository.getRecentSearches();
        refreshed.fold((_) {}, (list) => _recent = list);
        emit(MemberSearchFound(m, recentSearches: _recent));
      },
    );
  }
}
