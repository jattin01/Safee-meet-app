import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/emergency_share_entity.dart';
import '../../domain/repositories/emergency_share_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class EmergencyShareEvent extends Equatable {
  const EmergencyShareEvent();
  @override
  List<Object?> get props => [];
}

class EmergencyShareRequested extends EmergencyShareEvent {
  final String meetingId;
  const EmergencyShareRequested(this.meetingId);
  @override
  List<Object?> get props => [meetingId];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class EmergencyShareState extends Equatable {
  const EmergencyShareState();
  @override
  List<Object?> get props => [];
}

class EmergencyShareInitial extends EmergencyShareState {
  const EmergencyShareInitial();
}

class EmergencyShareLoading extends EmergencyShareState {
  const EmergencyShareLoading();
}

class EmergencyShareLoaded extends EmergencyShareState {
  final EmergencyShareEntity data;
  const EmergencyShareLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class EmergencyShareError extends EmergencyShareState {
  final String message;
  const EmergencyShareError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class EmergencyShareBloc
    extends Bloc<EmergencyShareEvent, EmergencyShareState> {
  final EmergencyShareRepository _repository;

  EmergencyShareBloc(this._repository) : super(const EmergencyShareInitial()) {
    on<EmergencyShareRequested>(_onRequested);
  }

  Future<void> _onRequested(
    EmergencyShareRequested event,
    Emitter<EmergencyShareState> emit,
  ) async {
    emit(const EmergencyShareLoading());
    final result = await _repository.getEmergencyShare(event.meetingId);
    result.fold(
      (f) => emit(EmergencyShareError(f.message)),
      (data) => emit(EmergencyShareLoaded(data)),
    );
  }
}
