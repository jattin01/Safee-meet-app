import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';

import 'package:safee_meet/core/services/api_client.dart';
import 'package:safee_meet/core/services/secure_storage_service.dart';
import 'package:safee_meet/features/sos/presentation/bloc/sos_bloc.dart';

class MockApiClient extends Mock implements ApiClient {
  @override
  Dio get dio => MockDio();
}

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockApiClient api;
  late MockSecureStorageService storage;

  setUp(() {
    api = MockApiClient();
    storage = MockSecureStorageService();
  });

  SosBloc _bloc() => SosBloc(api, storage);

  group('SosBloc initial state', () {
    test('initial state is SosInitial with empty contacts', () {
      final bloc = _bloc();
      expect(bloc.state, isA<SosInitial>());
      expect((bloc.state as SosInitial).contacts, isEmpty);
      bloc.close();
    });
  });

  group('SosHoldReleased before activation', () {
    blocTest<SosBloc, SosState>(
      'emits SosInitial when hold is released early',
      build: _bloc,
      act: (bloc) async {
        bloc.add(const SosHoldStarted());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SosHoldReleased());
      },
      expect: () => contains(isA<SosInitial>()),
    );
  });
}
