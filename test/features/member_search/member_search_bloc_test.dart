import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/member_search/domain/entities/member_entity.dart';
import 'package:safee_meet/features/member_search/domain/repositories/member_search_repository.dart';
import 'package:safee_meet/features/member_search/presentation/bloc/member_search_bloc.dart';

class MockMemberSearchRepository extends Mock implements MemberSearchRepository {}

final _member = MemberEntity(
  id: '1',
  name: 'Jane Smith',
  safeePIN: 'SM-XYZ789',
  trustScore: 92,
  verificationLevel: 'level2',
  subscriptionPlan: 'premium',
  rating: 4.9,
  totalMeetings: 45,
  badges: const ['verified', 'premium'],
);

void main() {
  late MockMemberSearchRepository repository;

  setUp(() {
    repository = MockMemberSearchRepository();
    when(() => repository.getRecentSearches())
        .thenAnswer((_) async => const Right([]));
  });

  MemberSearchBloc _bloc() => MemberSearchBloc(repository);

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
}
