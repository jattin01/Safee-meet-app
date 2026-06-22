import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';

// ── Entities ────────────────────────────────────────────────────────────────
class SosContactEntity {
  final String id;
  final String name;
  final String phone;
  bool notified;

  SosContactEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.notified = false,
  });
}

// ── Events ──────────────────────────────────────────────────────────────────
abstract class SosEvent extends Equatable {
  const SosEvent();
  @override
  List<Object?> get props => [];
}

class SosLoadRequested extends SosEvent {
  const SosLoadRequested();
}

class SosHoldStarted extends SosEvent {
  const SosHoldStarted();
}

class SosHoldReleased extends SosEvent {
  const SosHoldReleased();
}

class SosActivated extends SosEvent {
  const SosActivated();
}

class SosCancelled extends SosEvent {
  const SosCancelled();
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class SosState extends Equatable {
  const SosState();
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {
  final List<SosContactEntity> contacts;
  final double? lat;
  final double? lng;
  const SosInitial({required this.contacts, this.lat, this.lng});
  @override
  List<Object?> get props => [contacts, lat, lng];
}

class SosHolding extends SosState {
  final double progress; // 0.0–1.0 over ~2s hold
  const SosHolding(this.progress);
  @override
  List<Object?> get props => [progress];
}

class SosActivatedState extends SosState {
  final List<SosContactEntity> contacts;
  final int countdown; // seconds
  final double? lat;
  final double? lng;
  const SosActivatedState({
    required this.contacts,
    required this.countdown,
    this.lat,
    this.lng,
  });
  @override
  List<Object?> get props => [contacts, countdown, lat, lng];
}

class SosDone extends SosState {
  const SosDone();
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class SosBloc extends Bloc<SosEvent, SosState> {
  final ApiClient _api;
  final SecureStorageService _storage;
  Timer? _holdTimer;
  Timer? _countdownTimer;

  SosBloc(this._api, this._storage) : super(const SosInitial(contacts: [])) {
    on<SosLoadRequested>(_onLoad);
    on<SosHoldStarted>(_onHoldStarted);
    on<SosHoldReleased>(_onHoldReleased);
    on<SosActivated>(_onActivated);
    on<SosCancelled>(_onCancelled);
  }

  Future<void> _onLoad(SosLoadRequested _, Emitter<SosState> emit) async {
    try {
      final res = await _api.dio.get('/sos/contacts');
      final contacts = (res.data as List<dynamic>)
          .map((c) => SosContactEntity(
                id: c['id'] as String,
                name: c['name'] as String,
                phone: c['phone'] as String,
              ))
          .toList();
      emit(SosInitial(contacts: contacts));
    } catch (_) {
      emit(const SosInitial(contacts: []));
    }
  }

  void _onHoldStarted(SosHoldStarted _, Emitter<SosState> emit) {
    double progress = 0.0;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      progress += 40 / 2000; // fill in 2s
      if (progress >= 1.0) {
        t.cancel();
        add(const SosActivated());
      } else {
        if (!isClosed) add(_ProgressTick(progress));
      }
    });
    emit(const SosHolding(0.0));
    on<_ProgressTick>((event, emit) => emit(SosHolding(event.progress)));
  }

  void _onHoldReleased(SosHoldReleased _, Emitter<SosState> emit) {
    _holdTimer?.cancel();
    emit(const SosInitial(contacts: []));
  }

  Future<void> _onActivated(SosActivated _, Emitter<SosState> emit) async {
    _holdTimer?.cancel();
    // Send SOS to server
    try {
      await _api.dio.post('/sos/activate');
    } catch (_) {}

    final contacts = (state is SosInitial)
        ? (state as SosInitial).contacts.map((c) {
            c.notified = true;
            return c;
          }).toList()
        : <SosContactEntity>[];

    int countdown = 30;
    emit(SosActivatedState(contacts: contacts, countdown: countdown));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      if (countdown <= 0 || isClosed) {
        t.cancel();
      } else {
        if (!isClosed) add(_CountdownTick(countdown));
      }
    });
    on<_CountdownTick>((event, emit) {
      if (state is SosActivatedState) {
        final s = state as SosActivatedState;
        emit(SosActivatedState(
          contacts: s.contacts,
          countdown: event.seconds,
          lat: s.lat,
          lng: s.lng,
        ));
      }
    });
  }

  void _onCancelled(SosCancelled _, Emitter<SosState> emit) {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    emit(const SosDone());
  }

  @override
  Future<void> close() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}

// Internal events for timer ticks
class _ProgressTick extends SosEvent {
  final double progress;
  const _ProgressTick(this.progress);
  @override
  List<Object?> get props => [progress];
}

class _CountdownTick extends SosEvent {
  final int seconds;
  const _CountdownTick(this.seconds);
  @override
  List<Object?> get props => [seconds];
}
