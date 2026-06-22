import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/repositories/meetings_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class MeetingsEvent extends Equatable {
  const MeetingsEvent();
  @override
  List<Object?> get props => [];
}

class MeetingsLoadRequested extends MeetingsEvent {
  const MeetingsLoadRequested();
}

class MeetingLoadRequested extends MeetingsEvent {
  final String meetingId;
  const MeetingLoadRequested(this.meetingId);
  @override
  List<Object?> get props => [meetingId];
}

class MeetingScheduleRequested extends MeetingsEvent {
  final String partnerId;
  final DateTime scheduledAt;
  final MeetingPurpose purpose;
  final String location;
  final String? notes;
  const MeetingScheduleRequested({
    required this.partnerId,
    required this.scheduledAt,
    required this.purpose,
    required this.location,
    this.notes,
  });
  @override
  List<Object?> get props => [partnerId, scheduledAt, purpose, location];
}

class MeetingStatusUpdateRequested extends MeetingsEvent {
  final String meetingId;
  final MeetingStatus status;
  const MeetingStatusUpdateRequested({required this.meetingId, required this.status});
  @override
  List<Object?> get props => [meetingId, status];
}

class MeetingEndRequested extends MeetingsEvent {
  final String meetingId;
  const MeetingEndRequested(this.meetingId);
  @override
  List<Object?> get props => [meetingId];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class MeetingsState extends Equatable {
  const MeetingsState();
  @override
  List<Object?> get props => [];
}

class MeetingsInitial extends MeetingsState {
  const MeetingsInitial();
}

class MeetingsLoading extends MeetingsState {
  const MeetingsLoading();
}

class MeetingsListLoaded extends MeetingsState {
  final List<MeetingEntity> meetings;
  const MeetingsListLoaded(this.meetings);
  @override
  List<Object?> get props => [meetings];
}

class MeetingDetailLoaded extends MeetingsState {
  final MeetingEntity meeting;
  const MeetingDetailLoaded(this.meeting);
  @override
  List<Object?> get props => [meeting];
}

class MeetingScheduled extends MeetingsState {
  final MeetingEntity meeting;
  const MeetingScheduled(this.meeting);
  @override
  List<Object?> get props => [meeting];
}

class MeetingEnded extends MeetingsState {
  const MeetingEnded();
}

class MeetingsError extends MeetingsState {
  final String message;
  const MeetingsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class MeetingsBloc extends Bloc<MeetingsEvent, MeetingsState> {
  final MeetingsRepository _repository;

  MeetingsBloc(this._repository) : super(const MeetingsInitial()) {
    on<MeetingsLoadRequested>(_onList);
    on<MeetingLoadRequested>(_onDetail);
    on<MeetingScheduleRequested>(_onSchedule);
    on<MeetingStatusUpdateRequested>(_onStatusUpdate);
    on<MeetingEndRequested>(_onEnd);
  }

  Future<void> _onList(MeetingsLoadRequested _, Emitter<MeetingsState> emit) async {
    emit(const MeetingsLoading());
    final result = await _repository.getMeetings();
    result.fold(
      (f) => emit(MeetingsError(f.message)),
      (meetings) => emit(MeetingsListLoaded(meetings)),
    );
  }

  Future<void> _onDetail(MeetingLoadRequested event, Emitter<MeetingsState> emit) async {
    emit(const MeetingsLoading());
    final result = await _repository.getMeeting(event.meetingId);
    result.fold(
      (f) => emit(MeetingsError(f.message)),
      (m) => emit(MeetingDetailLoaded(m)),
    );
  }

  Future<void> _onSchedule(
    MeetingScheduleRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    emit(const MeetingsLoading());
    final result = await _repository.scheduleMeeting(
      partnerId: event.partnerId,
      scheduledAt: event.scheduledAt,
      purpose: event.purpose,
      location: event.location,
      notes: event.notes,
    );
    result.fold(
      (f) => emit(MeetingsError(f.message)),
      (m) => emit(MeetingScheduled(m)),
    );
  }

  Future<void> _onStatusUpdate(
    MeetingStatusUpdateRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    final result = await _repository.updateMeetingStatus(
      meetingId: event.meetingId,
      status: event.status,
    );
    result.fold(
      (f) => emit(MeetingsError(f.message)),
      (m) => emit(MeetingDetailLoaded(m)),
    );
  }

  Future<void> _onEnd(MeetingEndRequested event, Emitter<MeetingsState> emit) async {
    final result = await _repository.endMeeting(event.meetingId);
    result.fold(
      (f) => emit(MeetingsError(f.message)),
      (_) => emit(const MeetingEnded()),
    );
  }
}
