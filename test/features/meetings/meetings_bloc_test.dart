import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/meetings/domain/entities/meeting_entity.dart';
import 'package:safee_meet/features/meetings/domain/repositories/meetings_repository.dart';
import 'package:safee_meet/features/meetings/presentation/bloc/meetings_bloc.dart';

class MockMeetingsRepository extends Mock implements MeetingsRepository {}

final _meeting = MeetingEntity(
  id: 'm1',
  partnerId: 'p1',
  partnerName: 'Alice Smith',
  partnerVerificationLevel: 'level1',
  scheduledAt: DateTime(2025, 6, 20, 15, 0),
  purpose: MeetingPurpose.coffee,
  location: 'Central Park Cafe',
  status: MeetingStatus.scheduled,
  isHost: true,
);

void main() {
  late MockMeetingsRepository repository;

  setUpAll(() {
    registerFallbackValue(MeetingStatus.scheduled);
    registerFallbackValue(MeetingPurpose.coffee);
  });

  setUp(() {
    repository = MockMeetingsRepository();
  });

  MeetingsBloc _bloc() => MeetingsBloc(repository);

  group('MeetingsLoadRequested', () {
    blocTest<MeetingsBloc, MeetingsState>(
      'emits [Loading, ListLoaded] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.getMeetings())
            .thenAnswer((_) async => Right([_meeting]));
      },
      act: (bloc) => bloc.add(const MeetingsLoadRequested()),
      expect: () => [
        const MeetingsLoading(),
        MeetingsListLoaded([_meeting]),
      ],
    );

    blocTest<MeetingsBloc, MeetingsState>(
      'emits [Loading, Error] on failure',
      build: _bloc,
      setUp: () {
        when(() => repository.getMeetings())
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      act: (bloc) => bloc.add(const MeetingsLoadRequested()),
      expect: () => [
        const MeetingsLoading(),
        isA<MeetingsError>(),
      ],
    );
  });

  group('MeetingScheduleRequested', () {
    blocTest<MeetingsBloc, MeetingsState>(
      'emits [Loading, MeetingScheduled] on success',
      build: _bloc,
      setUp: () {
        when(
          () => repository.scheduleMeeting(
            partnerId: any(named: 'partnerId'),
            scheduledAt: any(named: 'scheduledAt'),
            purpose: any(named: 'purpose'),
            location: any(named: 'location'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Right(_meeting));
      },
      act: (bloc) => bloc.add(MeetingScheduleRequested(
        partnerId: 'p1',
        scheduledAt: DateTime(2025, 6, 20, 15, 0),
        purpose: MeetingPurpose.coffee,
        location: 'Central Park Cafe',
      )),
      expect: () => [
        const MeetingsLoading(),
        MeetingScheduled(_meeting),
      ],
    );
  });

  group('MeetingEndRequested', () {
    blocTest<MeetingsBloc, MeetingsState>(
      'emits [MeetingEnded] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.endMeeting(any()))
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const MeetingEndRequested('m1')),
      expect: () => [const MeetingEnded()],
    );
  });
}
