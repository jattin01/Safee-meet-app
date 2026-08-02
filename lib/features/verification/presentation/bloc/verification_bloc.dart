import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/verification_entity.dart';
import '../../domain/repositories/verification_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class VerificationEvent extends Equatable {
  const VerificationEvent();
  @override
  List<Object?> get props => [];
}

class VerificationStatusRequested extends VerificationEvent {
  const VerificationStatusRequested();
}

/// Asks our backend to open a Didit session; the resulting token is what the
/// page passes to `DiditSdk.startVerification`.
class VerificationDiditSessionRequested extends VerificationEvent {
  const VerificationDiditSessionRequested();
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class VerificationState extends Equatable {
  const VerificationState();
  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {
  const VerificationInitial();
}

class VerificationLoading extends VerificationState {
  const VerificationLoading();
}

class VerificationStatusLoaded extends VerificationState {
  final VerificationStatusEntity status;
  const VerificationStatusLoaded(this.status);
  @override
  List<Object?> get props => [status];
}

/// Session token ready — the page's BlocListener launches the Didit SDK the
/// moment this is emitted.
class VerificationDiditSessionReady extends VerificationState {
  final DiditSessionEntity session;
  const VerificationDiditSessionReady(this.session);
  @override
  List<Object?> get props => [session];
}

class VerificationError extends VerificationState {
  final String message;
  const VerificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _repository;

  VerificationBloc(this._repository) : super(const VerificationInitial()) {
    on<VerificationStatusRequested>(_onStatusRequested);
    on<VerificationDiditSessionRequested>(_onDiditSessionRequested);
  }

  Future<void> _onStatusRequested(
    VerificationStatusRequested _,
    Emitter<VerificationState> emit,
  ) async {
    // Skip the full-screen loading state on a pull-to-refresh — only the
    // very first load should blank the screen while it fetches.
    if (state is! VerificationStatusLoaded) emit(const VerificationLoading());
    final result = await _repository.getVerificationStatus();
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (s) => emit(VerificationStatusLoaded(s)),
    );
  }

  Future<void> _onDiditSessionRequested(
    VerificationDiditSessionRequested _,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationLoading());
    final result = await _repository.createDiditSession();
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (session) => emit(VerificationDiditSessionReady(session)),
    );
  }
}
