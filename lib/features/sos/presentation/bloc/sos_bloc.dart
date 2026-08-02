import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
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
  final String? meetingId;
  const SosHoldStarted({this.meetingId});
  @override
  List<Object?> get props => [meetingId];
}

class SosHoldReleased extends SosEvent {
  const SosHoldReleased();
}

class SosActivated extends SosEvent {
  final String? meetingId;
  const SosActivated({this.meetingId});
  @override
  List<Object?> get props => [meetingId];
}

class SosCancelled extends SosEvent {
  const SosCancelled();
}

// Internal events driving timers/streams back through the bloc.
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

class _LocationUpdated extends SosEvent {
  final Position position;
  const _LocationUpdated(this.position);
  @override
  List<Object?> get props => [position];
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
  final String? incidentId;
  const SosActivatedState({
    required this.contacts,
    required this.countdown,
    this.lat,
    this.lng,
    this.incidentId,
  });
  @override
  List<Object?> get props => [contacts, countdown, lat, lng, incidentId];
}

class SosDone extends SosState {
  const SosDone();
}

/// Emitted instead of SosActivatedState when a real GPS fix couldn't be
/// obtained, or the trigger request itself failed — the SOS is never sent
/// with a fabricated/placeholder (0, 0) location.
class SosError extends SosState {
  final String message;
  final List<SosContactEntity> contacts;
  const SosError({required this.message, required this.contacts});
  @override
  List<Object?> get props => [message, contacts];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class SosBloc extends Bloc<SosEvent, SosState> {
  final ApiClient _api;
  // ignore: unused_field
  final SecureStorageService _storage;
  Timer? _holdTimer;
  Timer? _countdownTimer;
  StreamSubscription<Position>? _positionSub;
  String? _activeIncidentId;
  // Bloc-instance cache of the loaded contacts — `state` has already moved
  // on to SosHolding by the time _onActivated runs (via the internal hold
  // timer), so reading `state is SosInitial` there always misses; keep our
  // own reference instead.
  List<SosContactEntity> _contacts = [];

  SosBloc(this._api, this._storage) : super(const SosInitial(contacts: [])) {
    on<SosLoadRequested>(_onLoad);
    on<SosHoldStarted>(_onHoldStarted);
    on<SosHoldReleased>(_onHoldReleased);
    on<SosActivated>(_onActivated);
    on<SosCancelled>(_onCancelled);
    on<_ProgressTick>((event, emit) => emit(SosHolding(event.progress)));
    on<_CountdownTick>(_onCountdownTick);
    on<_LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onLoad(SosLoadRequested _, Emitter<SosState> emit) async {
    try {
      final res = await _api.dio.get('/v1/emergency-contact');
      final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      final contacts = list
          .map((c) => SosContactEntity(
                id: c['id'].toString(),
                name: c['full_name'] as String,
                phone: c['phone_number'] as String,
              ))
          .toList();
      _contacts = contacts;
      emit(SosInitial(contacts: contacts));
    } catch (_) {
      _contacts = [];
      emit(const SosInitial(contacts: []));
    }
  }

  // Returns a real GPS fix or a specific reason it couldn't be obtained —
  // never a silent null-turned-into-(0,0). Checked in this order: location
  // services on, permission granted, then an actual fix within 8s.
  Future<({Position? position, String? error})> _resolvePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          position: null,
          error: 'Turn on location services to send an SOS alert.'
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          position: null,
          error: 'Location permission is required to send an SOS alert.'
        );
      }

      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      return (position: position, error: null);
    } on TimeoutException {
      return (
        position: null,
        error: 'Could not get your current location. Please try again.'
      );
    } catch (_) {
      return (
        position: null,
        error: 'Unable to get your current location. Please try again.'
      );
    }
  }

  void _onHoldStarted(SosHoldStarted event, Emitter<SosState> emit) {
    double progress = 0.0;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      progress += 40 / 2000; // fill in 2s
      if (progress >= 1.0) {
        t.cancel();
        add(SosActivated(meetingId: event.meetingId));
      } else {
        if (!isClosed) add(_ProgressTick(progress));
      }
    });
    emit(const SosHolding(0.0));
  }

  void _onHoldReleased(SosHoldReleased _, Emitter<SosState> emit) {
    _holdTimer?.cancel();
    emit(const SosInitial(contacts: []));
  }

  Future<void> _onActivated(SosActivated event, Emitter<SosState> emit) async {
    _holdTimer?.cancel();

    final resolved = await _resolvePosition();
    final position = resolved.position;
    if (position == null) {
      emit(SosError(
        message: resolved.error ?? 'Unable to get your current location.',
        contacts: _contacts,
      ));
      return;
    }

    // Send SOS to server — reporter comes from the auth token, not a
    // client-supplied id. meetingId (when triggered from an active meeting)
    // ties the incident to that meeting on the backend.
    try {
      final res = await _api.dio.post('/v1/sos/trigger', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        if (event.meetingId != null) 'meeting_id': event.meetingId,
      });
      _activeIncidentId = res.data['incident']?['id']?.toString();
    } catch (_) {
      emit(SosError(
        message: 'Failed to send SOS alert. Please try again.',
        contacts: _contacts,
      ));
      return;
    }

    final contacts = _contacts.map((c) {
      c.notified = true;
      return c;
    }).toList();

    int countdown = 30;
    emit(SosActivatedState(
      contacts: contacts,
      countdown: countdown,
      lat: position.latitude,
      lng: position.longitude,
      incidentId: _activeIncidentId,
    ));

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      if (countdown <= 0 || isClosed) {
        t.cancel();
      } else {
        if (!isClosed) add(_CountdownTick(countdown));
      }
    });

    // Keep the displayed GPS coordinates live for as long as the SOS stays
    // activated, so the on-screen location always matches the user's
    // current position, not just the fix taken at trigger time.
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) => add(_LocationUpdated(pos)),
      onError: (_) {},
    );
  }

  void _onCountdownTick(_CountdownTick event, Emitter<SosState> emit) {
    if (state is SosActivatedState) {
      final s = state as SosActivatedState;
      emit(SosActivatedState(
        contacts: s.contacts,
        countdown: event.seconds,
        lat: s.lat,
        lng: s.lng,
        incidentId: s.incidentId,
      ));
    }
  }

  void _onLocationUpdated(_LocationUpdated event, Emitter<SosState> emit) {
    if (state is SosActivatedState) {
      final s = state as SosActivatedState;
      emit(SosActivatedState(
        contacts: s.contacts,
        countdown: s.countdown,
        lat: event.position.latitude,
        lng: event.position.longitude,
        incidentId: s.incidentId,
      ));
    }
  }

  Future<void> _onCancelled(SosCancelled _, Emitter<SosState> emit) async {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    _positionSub?.cancel();
    if (_activeIncidentId != null) {
      try {
        await _api.dio.post('/v1/sos/$_activeIncidentId/resolve');
      } catch (_) {}
      _activeIncidentId = null;
    }
    emit(const SosDone());
  }

  @override
  Future<void> close() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    _positionSub?.cancel();
    return super.close();
  }
}
