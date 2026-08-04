import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/api_client.dart';

// ── Events ─────────────────────────────────────────────────────────────────
abstract class GpsEvent extends Equatable {
  const GpsEvent();
  @override
  List<Object?> get props => [];
}

class GpsTrackingStarted extends GpsEvent {
  final String meetingId;
  const GpsTrackingStarted(this.meetingId);
  @override
  List<Object?> get props => [meetingId];
}

class GpsTrackingStopped extends GpsEvent {
  const GpsTrackingStopped();
}

class _LocationUpdated extends GpsEvent {
  final Position position;
  const _LocationUpdated(this.position);
  @override
  List<Object?> get props => [position];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class GpsState extends Equatable {
  const GpsState();
  @override
  List<Object?> get props => [];
}

class GpsIdle extends GpsState {
  const GpsIdle();
}

class GpsPermissionDenied extends GpsState {
  const GpsPermissionDenied();
}

class GpsTracking extends GpsState {
  final double lat;
  final double lng;
  final double accuracy;
  const GpsTracking({required this.lat, required this.lng, required this.accuracy});
  @override
  List<Object?> get props => [lat, lng, accuracy];
}

class GpsError extends GpsState {
  final String message;
  const GpsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────
class GpsTrackingBloc extends Bloc<GpsEvent, GpsState> {
  final ApiClient _api;
  StreamSubscription<Position>? _positionSub;
  String? _activeMeetingId;

  GpsTrackingBloc(this._api) : super(const GpsIdle()) {
    on<GpsTrackingStarted>(_onStart);
    on<GpsTrackingStopped>(_onStop);
    on<_LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onStart(GpsTrackingStarted event, Emitter<GpsState> emit) async {
    _activeMeetingId = event.meetingId;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.denied ||
          result == LocationPermission.deniedForever) {
        emit(const GpsPermissionDenied());
        return;
      }
    }

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) => add(_LocationUpdated(pos)),
      onError: (_) => add(const GpsTrackingStopped()),
    );
  }

  void _onStop(GpsTrackingStopped _, Emitter<GpsState> emit) {
    _positionSub?.cancel();
    _activeMeetingId = null;
    emit(const GpsIdle());
  }

  Future<void> _onLocationUpdated(
    _LocationUpdated event,
    Emitter<GpsState> emit,
  ) async {
    emit(GpsTracking(
      lat: event.position.latitude,
      lng: event.position.longitude,
      accuracy: event.position.accuracy,
    ));
    // Broadcast to server
    if (_activeMeetingId != null) {
      try {
        await _api.dio.post('/v1/update-location', data: {
          'latitude': event.position.latitude,
          'longitude': event.position.longitude,
        });
      } catch (e) {
        debugPrint('[GpsTracking] update-location failed: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    return super.close();
  }
}
