import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/services/secure_storage_service.dart';
import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/member_search/domain/entities/member_entity.dart';
import 'package:safee_meet/features/member_search/domain/repositories/member_search_repository.dart';
import 'package:safee_meet/features/member_search/presentation/bloc/member_search_bloc.dart';
import 'package:safee_meet/features/messaging/domain/use_cases/create_or_get_room_use_case.dart';

class MockMemberSearchRepository extends Mock
    implements MemberSearchRepository {}

class MockCreateOrGetRoomUseCase extends Mock
    implements CreateOrGetRoomUseCase {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

final _member = MemberEntity(
  id: '1',
  name: 'Jane Smith',
  safeePIN: 'SM-XYZ789',
  trustScore: 92,
  verificationLevel: 'level2',
  subscriptionPlan: 'premium',
  safetyScore: 98,
  totalMeetings: 45,
  badges: const ['verified', 'premium'],
);

void main() {
  late MockMemberSearchRepository repository;
  late MockCreateOrGetRoomUseCase createOrGetRoom;
  late MockSecureStorageService secureStorage;

  setUp(() {
    repository = MockMemberSearchRepository();
    createOrGetRoom = MockCreateOrGetRoomUseCase();
    secureStorage = MockSecureStorageService();
    when(() => repository.getRecentSearches())
        .thenAnswer((_) async => const Right([]));
    // The searcher's own id/name — deliberately different from _member.id
    // so _addMatchToChatList's "don't chat with yourself" guard never
    // short-circuits these tests.
    when(() => secureStorage.getUserId())
        .thenAnswer((_) async => 'current-user-id');
    when(() => secureStorage.getUserName())
        .thenAnswer((_) async => 'Current User');
    // Auto-add-to-chat is fire-and-forget and its result is never inspected
    // by the bloc — this lenient default just needs to exist so every test
    // below doesn't hit a MissingStubError the moment a search succeeds.
    when(() => createOrGetRoom.call(
          currentUserId: any(named: 'currentUserId'),
          partnerId: any(named: 'partnerId'),
          currentUserName: any(named: 'currentUserName'),
          partnerName: any(named: 'partnerName'),
          partnerAvatarUrl: any(named: 'partnerAvatarUrl'),
        )).thenAnswer((_) async => const Left(UnknownFailure()));
  });

  MemberSearchBloc _bloc() =>
      MemberSearchBloc(repository, createOrGetRoom, secureStorage);

  group('PINSearchRequested', () {
    blocTest<MemberSearchBloc, MemberSearchState>(
      'emits [Loading, Found] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.searchByPIN(any()))
            .thenAnswer((_) async => Right(_member));
      },
      act: (bloc) => bloc.add(const PINSearchRequested('SM-XYZ789')),
      expect: () => [
        const MemberSearchLoading(),
        MemberSearchFound(_member),
      ],
    );

    blocTest<MemberSearchBloc, MemberSearchState>(
      'emits [Loading, Error] on not found',
      build: _bloc,
      setUp: () {
        when(() => repository.searchByPIN(any())).thenAnswer(
          (_) async => const Left(ValidationFailure('Member not found')),
        );
      },
      act: (bloc) => bloc.add(const PINSearchRequested('SM-XXXXX')),
      expect: () => [
        const MemberSearchLoading(),
        isA<MemberSearchError>(),
      ],
    );

    blocTest<MemberSearchBloc, MemberSearchState>(
      'does nothing for PIN shorter than 6 chars',
      build: _bloc,
      act: (bloc) => bloc.add(const PINSearchRequested('ABC')),
      expect: () => [],
    );
  });

  group('MemberSearchReset', () {
    blocTest<MemberSearchBloc, MemberSearchState>(
      'emits [MemberSearchInitial]',
      build: _bloc,
      seed: () => MemberSearchFound(_member),
      act: (bloc) => bloc.add(const MemberSearchReset()),
      expect: () => [const MemberSearchInitial()],
    );
  });

  group('RecentSearchesRequested', () {
    blocTest<MemberSearchBloc, MemberSearchState>(
      'loads previously-searched members into the current state',
      build: _bloc,
      setUp: () {
        when(() => repository.getRecentSearches())
            .thenAnswer((_) async => Right([_member]));
      },
      act: (bloc) => bloc.add(const RecentSearchesRequested()),
      expect: () => [
        const MemberSearchInitial(isLoadingRecentSearches: true),
        MemberSearchInitial(recentSearches: [_member]),
      ],
    );
  });

  group('RecentMemberSelected', () {
    blocTest<MemberSearchBloc, MemberSearchState>(
      'emits MemberSearchFound directly, without calling the search API',
      build: _bloc,
      act: (bloc) => bloc.add(RecentMemberSelected(_member)),
      verify: (_) {
        verifyNever(() => repository.searchByPIN(any()));
        verifyNever(() => repository.searchByQR(any()));
      },
      expect: () => [MemberSearchFound(_member)],
    );
  });

  group('PINSearchRequested recentSearches refresh', () {
    blocTest<MemberSearchBloc, MemberSearchState>(
      'carries the refreshed recent list on the Found state after a search',
      build: _bloc,
      setUp: () {
        when(() => repository.searchByPIN(any()))
            .thenAnswer((_) async => Right(_member));
        when(() => repository.getRecentSearches())
            .thenAnswer((_) async => Right([_member]));
      },
      act: (bloc) => bloc.add(const PINSearchRequested('SM-XYZ789')),
      expect: () => [
        const MemberSearchLoading(),
        MemberSearchFound(_member, recentSearches: [_member]),
      ],
    );
  });

  group('Auto-add matched user to chat list', () {
    // _addMatchToChatList is fire-and-forget (not awaited by the event
    // handler), so a short `wait` gives its mocked Futures a chance to
    // resolve before `verify` runs.
    blocTest<MemberSearchBloc, MemberSearchState>(
      'ensures a chat room exists for the matched member after a '
      'successful PIN search',
      build: _bloc,
      setUp: () {
        when(() => repository.searchByPIN(any()))
            .thenAnswer((_) async => Right(_member));
      },
      act: (bloc) => bloc.add(const PINSearchRequested('SM-XYZ789')),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => createOrGetRoom.call(
              currentUserId: 'current-user-id',
              partnerId: _member.id,
              currentUserName: 'Current User',
              partnerName: _member.name,
              partnerAvatarUrl: _member.avatarUrl,
            )).called(1);
      },
    );

    blocTest<MemberSearchBloc, MemberSearchState>(
      'also ensures a chat room exists when selecting a recent search',
      build: _bloc,
      act: (bloc) => bloc.add(RecentMemberSelected(_member)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => createOrGetRoom.call(
              currentUserId: 'current-user-id',
              partnerId: _member.id,
              currentUserName: 'Current User',
              partnerName: _member.name,
              partnerAvatarUrl: _member.avatarUrl,
            )).called(1);
      },
    );

    blocTest<MemberSearchBloc, MemberSearchState>(
      'never calls createOrGetRoom when the match is the searcher themself',
      build: _bloc,
      setUp: () {
        when(() => secureStorage.getUserId())
            .thenAnswer((_) async => _member.id);
      },
      act: (bloc) => bloc.add(RecentMemberSelected(_member)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verifyNever(() => createOrGetRoom.call(
              currentUserId: any(named: 'currentUserId'),
              partnerId: any(named: 'partnerId'),
              currentUserName: any(named: 'currentUserName'),
              partnerName: any(named: 'partnerName'),
              partnerAvatarUrl: any(named: 'partnerAvatarUrl'),
            ));
      },
    );
  });
}
