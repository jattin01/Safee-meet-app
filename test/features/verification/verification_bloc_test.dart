import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/verification/domain/entities/verification_entity.dart';
import 'package:safee_meet/features/verification/domain/repositories/verification_repository.dart';
import 'package:safee_meet/features/verification/presentation/bloc/verification_bloc.dart';

class MockVerificationRepository extends Mock implements VerificationRepository {}

final _status = VerificationStatusEntity(
  trustScore: 72,
  verificationLevel: 'level1',
  level1Complete: true,
  level2Complete: false,
  professionalComplete: false,
  safetyMetricMeetings: 0.8,
  safetyMetricResponsiveness: 0.9,
  safetyMetricReviews: 0.75,
  recentReviews: const [],
);

void main() {
  late MockVerificationRepository repository;

  setUp(() {
    repository = MockVerificationRepository();
  });

  VerificationBloc _bloc() => VerificationBloc(repository);

  group('VerificationStatusRequested', () {
    blocTest<VerificationBloc, VerificationState>(
      'emits [VerificationLoading, VerificationStatusLoaded] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.getVerificationStatus())
            .thenAnswer((_) async => Right(_status));
      },
      act: (bloc) => bloc.add(const VerificationStatusRequested()),
      expect: () => [
        const VerificationLoading(),
        VerificationStatusLoaded(_status),
      ],
    );

    blocTest<VerificationBloc, VerificationState>(
      'emits [VerificationLoading, VerificationError] on failure',
      build: _bloc,
      setUp: () {
        when(() => repository.getVerificationStatus())
            .thenAnswer((_) async => const Left(ServerFailure('Server error')));
      },
      act: (bloc) => bloc.add(const VerificationStatusRequested()),
      expect: () => [
        const VerificationLoading(),
        isA<VerificationError>(),
      ],
    );
  });
}
