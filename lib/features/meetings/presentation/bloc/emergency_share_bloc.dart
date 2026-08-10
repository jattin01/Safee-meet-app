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

  // bloc's default EventTransformer processes events *concurrently* (no
  // transformer is passed to `on<>` below), so LiveLocationPage's 10-second
  // poll would otherwise start a brand-new request for the same data even
  // while a previous one is still in flight — if a single response ever
  // takes ≥10s, duplicate overlapping requests start stacking, competing
  // for bandwidth and making a slow response slower still. Guard against
  // that instead: drop a new request while one's already running — the
  // in-flight one already covers it, and any caller awaiting the next
  // Loaded/Error (e.g. pull-to-refresh) still resolves normally off of it.
  bool _isFetching = false;

  EmergencyShareBloc(this._repository) : super(const EmergencyShareInitial()) {
    on<EmergencyShareRequested>(_onRequested);
  }

  Future<void> _onRequested(
    EmergencyShareRequested event,
    Emitter<EmergencyShareState> emit,
  ) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      // Skip the full-screen loading state on a pull-to-refresh — only the
      // very first load should blank the screen while it fetches.
      if (state is! EmergencyShareLoaded) emit(const EmergencyShareLoading());
      final result = await _repository.getEmergencyShare(event.meetingId);
      result.fold(
        (f) => emit(EmergencyShareError(f.message)),
        (data) => emit(EmergencyShareLoaded(data)),
      );
    } finally {
      _isFetching = false;
    }
  }
}
