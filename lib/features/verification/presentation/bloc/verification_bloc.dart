import 'dart:io';
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

class IdDocumentUploaded extends VerificationEvent {
  final File front;
  final File back;
  const IdDocumentUploaded({required this.front, required this.back});
  @override
  List<Object?> get props => [front, back];
}

class SelfieUploaded extends VerificationEvent {
  final File selfie;
  const SelfieUploaded(this.selfie);
  @override
  List<Object?> get props => [selfie];
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

class VerificationUploading extends VerificationState {
  const VerificationUploading();
}

class VerificationUploadSuccess extends VerificationState {
  final VerificationStep nextStep;
  const VerificationUploadSuccess(this.nextStep);
  @override
  List<Object?> get props => [nextStep];
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
    on<IdDocumentUploaded>(_onIdUploaded);
    on<SelfieUploaded>(_onSelfieUploaded);
  }

  Future<void> _onStatusRequested(
    VerificationStatusRequested _,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationLoading());
    final result = await _repository.getVerificationStatus();
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (s) => emit(VerificationStatusLoaded(s)),
    );
  }

  Future<void> _onIdUploaded(
    IdDocumentUploaded event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationUploading());
    final result = await _repository.uploadIdDocument(
      frontImage: event.front,
      backImage: event.back,
    );
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (_) => emit(const VerificationUploadSuccess(VerificationStep.selfie)),
    );
  }

  Future<void> _onSelfieUploaded(
    SelfieUploaded event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationUploading());
    final result = await _repository.uploadSelfie(event.selfie);
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (_) => emit(const VerificationUploadSuccess(VerificationStep.processing)),
    );
  }
}
