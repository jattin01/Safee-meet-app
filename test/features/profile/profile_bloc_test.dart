import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/profile/domain/entities/profile_entity.dart';
import 'package:safee_meet/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:safee_meet/features/profile/presentation/bloc/profile_bloc.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

final _profile = ProfileEntity(
  id: 'u1',
  name: 'John Doe',
  safeePIN: 'SM-ABC123',
  trustScore: 85,
  verificationLevel: 'level1',
  subscriptionPlan: 'premium',
  safetyScore: 92,
  totalMeetings: 22,
  totalReviews: 8,
  badges: const ['verified'],
);

void main() {
  late MockProfileRepository repository;

  setUp(() {
    repository = MockProfileRepository();
  });

  ProfileBloc _bloc() => ProfileBloc(repository);

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.getProfile())
            .thenAnswer((_) async => Right(_profile));
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        const ProfileLoading(),
        ProfileLoaded(profile: _profile),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] on failure',
      build: _bloc,
      setUp: () {
        when(() => repository.getProfile())
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        const ProfileLoading(),
        isA<ProfileError>(),
      ],
    );
  });
}
