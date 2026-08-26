import 'dart:async';

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
  // Completed once this specific request finishes, independent of whether
  // the resulting state actually changed — Bloc's emit() silently skips the
  // stream when the new state is equal to the current one (e.g. a
  // pull-to-refresh that returns unchanged data), so callers that need to
  // know "the request is done" (like RefreshIndicator) can't rely on
  // observing a new state on the stream.
  final Completer<void>? done;
  const VerificationStatusRequested({this.done});
}

/// Asks our backend to open a Didit session; the resulting token is what the
/// page passes to `DiditSdk.startVerification`.
class VerificationDiditSessionRequested extends VerificationEvent {
  const VerificationDiditSessionRequested();
}

/// Submits the user's consent to the criminal background check.
class BackgroundConsentSubmitted extends VerificationEvent {
  const BackgroundConsentSubmitted();
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

/// Consent API call is in progress — used to show a loading indicator in the
/// popup's Agree button without blanking the whole screen.
class BackgroundConsentLoading extends VerificationState {
  const BackgroundConsentLoading();
}

/// Consent was successfully recorded by the backend and saved locally.
class BackgroundConsentSuccess extends VerificationState {
  const BackgroundConsentSuccess();
}

/// Consent API call failed.
class BackgroundConsentError extends VerificationState {
  final String message;
  const BackgroundConsentError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _repository;

  VerificationBloc(this._repository) : super(const VerificationInitial()) {
    on<VerificationStatusRequested>(_onStatusRequested);
    on<VerificationDiditSessionRequested>(_onDiditSessionRequested);
    on<BackgroundConsentSubmitted>(_onBackgroundConsentSubmitted);
  }

  Future<void> _onStatusRequested(
    VerificationStatusRequested event,
    Emitter<VerificationState> emit,
  ) async {
    try {
      // Skip the full-screen loading state on a pull-to-refresh — only the
      // very first load should blank the screen while it fetches.
      if (state is! VerificationStatusLoaded) emit(const VerificationLoading());
      final result = await _repository.getVerificationStatus();
      result.fold(
        (f) => emit(VerificationError(f.message)),
        (s) => emit(VerificationStatusLoaded(s)),
      );
    } finally {
      event.done?.complete();
    }
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

  Future<void> _onBackgroundConsentSubmitted(
    BackgroundConsentSubmitted _,
    Emitter<VerificationState> emit,
  ) async {
    // Capture the current loaded state so we can restore it after the consent
    // call — we don't want to blank the whole verification screen.
    final previous = state;
    emit(const BackgroundConsentLoading());
    final result = await _repository.submitBackgroundConsent();
    result.fold(
      (f) => emit(BackgroundConsentError(f.message)),
      (_) {
        emit(const BackgroundConsentSuccess());
        // Restore the previous loaded state so the page remains fully visible.
        if (previous is VerificationStatusLoaded) emit(previous);
      },
    );
  }
}
