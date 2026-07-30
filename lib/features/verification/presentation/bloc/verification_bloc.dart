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

class VerificationProgressRequested extends VerificationEvent {
  const VerificationProgressRequested();
}

class VerificationSubmitted extends VerificationEvent {
  final File faceIdImage;
  final File nationalIdFrontImage;
  final File nationalIdBackImage;
  final String nationalIdNumber;
  final String nationalIdCountry;

  const VerificationSubmitted({
    required this.faceIdImage,
    required this.nationalIdFrontImage,
    required this.nationalIdBackImage,
    required this.nationalIdNumber,
    required this.nationalIdCountry,
  });

  @override
  List<Object?> get props => [
        faceIdImage,
        nationalIdFrontImage,
        nationalIdBackImage,
        nationalIdNumber,
        nationalIdCountry,
      ];
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

class VerificationProgressLoaded extends VerificationState {
  final VerificationEntity progress;
  const VerificationProgressLoaded(this.progress);
  @override
  List<Object?> get props => [progress];
}

class VerificationUploading extends VerificationState {
  const VerificationUploading();
}

class VerificationUploadSuccess extends VerificationState {
  final String message;
  final VerificationSubmitEntity data;
  const VerificationUploadSuccess({required this.message, required this.data});
  @override
  List<Object?> get props => [message, data];
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
    on<VerificationProgressRequested>(_onProgressRequested);
    on<VerificationSubmitted>(_onSubmitted);
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

  Future<void> _onProgressRequested(
    VerificationProgressRequested _,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationLoading());
    final result = await _repository.getVerificationProgress();
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (p) => emit(VerificationProgressLoaded(p)),
    );
  }

  Future<void> _onSubmitted(
    VerificationSubmitted event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationUploading());
    final result = await _repository.submitVerification(
      faceIdImage: event.faceIdImage,
      nationalIdFrontImage: event.nationalIdFrontImage,
      nationalIdBackImage: event.nationalIdBackImage,
      nationalIdNumber: event.nationalIdNumber,
      nationalIdCountry: event.nationalIdCountry,
    );
    result.fold(
      (f) => emit(VerificationError(f.message)),
      (r) => emit(VerificationUploadSuccess(message: r.message, data: r.data)),
    );
  }
}
