import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/shared/failures/failures.dart';
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
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? itemOrService;
  const MeetingScheduleRequested({
    required this.partnerId,
    required this.scheduledAt,
    required this.purpose,
    required this.location,
    this.latitude,
    this.longitude,
    this.notes,
    this.itemOrService,
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

class MeetingApproveRequested extends MeetingsEvent {
  final String meetingId;
  const MeetingApproveRequested(this.meetingId);
  @override
  List<Object?> get props => [meetingId];
}

class MeetingDenyRequested extends MeetingsEvent {
  final String meetingId;
  const MeetingDenyRequested(this.meetingId);
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
    on<MeetingApproveRequested>(_onApprove);
    on<MeetingDenyRequested>(_onDeny);
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
      latitude: event.latitude,
      longitude: event.longitude,
      notes: event.notes,
      itemOrService: event.itemOrService,
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

  Future<void> _onApprove(
    MeetingApproveRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    await _optimisticStatusUpdate(
      emit: emit,
      meetingId: event.meetingId,
      optimisticStatus: MeetingStatus.scheduled,
      action: () => _repository.approveMeeting(event.meetingId),
    );
  }

  Future<void> _onDeny(
    MeetingDenyRequested event,
    Emitter<MeetingsState> emit,
  ) async {
    await _optimisticStatusUpdate(
      emit: emit,
      meetingId: event.meetingId,
      optimisticStatus: MeetingStatus.declined,
      action: () => _repository.denyMeeting(event.meetingId),
    );
  }

  // Flips the meeting's status in the already-loaded list immediately, so
  // the card moves to the right tab in the same frame the user taps
  // Approve/Deny — instead of waiting on a full list refetch. Reverts to
  // the pre-action list (and surfaces an error) if the request fails.
  Future<void> _optimisticStatusUpdate({
    required Emitter<MeetingsState> emit,
    required String meetingId,
    required MeetingStatus optimisticStatus,
    required Future<Either<Failure, void>> Function() action,
  }) async {
    final previousState = state;
    if (previousState is MeetingsListLoaded) {
      final optimistic = previousState.meetings
          .map((m) => m.id == meetingId ? m.copyWith(status: optimisticStatus) : m)
          .toList();
      emit(MeetingsListLoaded(optimistic));
    }

    final result = await action();
    result.fold(
      (f) {
        if (previousState is MeetingsListLoaded) emit(previousState);
        emit(MeetingsError(f.message));
      },
      (_) {},
    );
  }
}
