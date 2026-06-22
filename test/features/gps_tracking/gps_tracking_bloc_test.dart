import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/services/api_client.dart';
import 'package:safee_meet/core/services/secure_storage_service.dart';
import 'package:safee_meet/features/gps_tracking/presentation/bloc/gps_tracking_bloc.dart';

class MockApiClient extends Mock implements ApiClient {
  @override
  Dio get dio => MockDio();
}

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  GpsTrackingBloc _bloc() => GpsTrackingBloc(api);

  test('initial state is GpsIdle', () {
    final bloc = _bloc();
    expect(bloc.state, isA<GpsIdle>());
    bloc.close();
  });

  // GpsTrackingStarted relies on Geolocator platform channel which cannot be
  // invoked in unit tests without platform mock setup. Covered in integration
  // tests instead.

  group('GpsTrackingStopped', () {
    blocTest<GpsTrackingBloc, GpsState>(
      'emits GpsIdle when stopped',
      build: _bloc,
      // Seed with GpsTracking state to make the stop meaningful
      seed: () =>
          const GpsTracking(lat: 37.7749, lng: -122.4194, accuracy: 5.0),
      act: (bloc) => bloc.add(const GpsTrackingStopped()),
      expect: () => [const GpsIdle()],
    );
  });
}
