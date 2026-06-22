import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// ── States ─────────────────────────────────────────────────────────────────
abstract class MemberSearchState extends Equatable {
  const MemberSearchState();
  @override
  List<Object?> get props => [];
}

class MemberSearchInitial extends MemberSearchState {
  const MemberSearchInitial();
}

class MemberSearchLoading extends MemberSearchState {
  const MemberSearchLoading();
}

class MemberSearchFound extends MemberSearchState {
  final MemberEntity member;
  const MemberSearchFound(this.member);
  @override
  List<Object?> get props => [member];
}

class MemberSearchError extends MemberSearchState {
  final String message;
  const MemberSearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class MemberSearchBloc extends Bloc<MemberSearchEvent, MemberSearchState> {
  final MemberSearchRepository _repository;

  MemberSearchBloc(this._repository) : super(const MemberSearchInitial()) {
    on<PINSearchRequested>(_onPIN);
    on<QRSearchRequested>(_onQR);
    on<MemberSearchReset>((_,e) => e(const MemberSearchInitial()));
  }

  Future<void> _onPIN(PINSearchRequested event, Emitter<MemberSearchState> emit) async {
    if (event.pin.length < 6) return;
    emit(const MemberSearchLoading());
    final result = await _repository.searchByPIN(event.pin);
    result.fold(
      (f) => emit(MemberSearchError(f.message)),
      (m) => emit(MemberSearchFound(m)),
    );
  }

  Future<void> _onQR(QRSearchRequested event, Emitter<MemberSearchState> emit) async {
    emit(const MemberSearchLoading());
    final result = await _repository.searchByQR(event.qrCode);
    result.fold(
      (f) => emit(MemberSearchError(f.message)),
      (m) => emit(MemberSearchFound(m)),
    );
  }
}
