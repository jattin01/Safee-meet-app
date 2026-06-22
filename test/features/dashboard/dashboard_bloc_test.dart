import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:safee_meet/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:safee_meet/features/dashboard/domain/use_cases/get_dashboard_use_case.dart';
import 'package:safee_meet/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:safee_meet/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:safee_meet/features/dashboard/presentation/bloc/dashboard_state.dart';

class MockGetDashboardUseCase extends Mock implements GetDashboardUseCase {}
class MockDashboardRepository extends Mock implements DashboardRepository {}

final _dashboard = DashboardEntity(
  userId: '1',
  name: 'John Doe',
  trustScore: 85,
  verificationLevel: 'level1',
  isLocationSharing: false,
  recentMeetings: const [],
  subscriptionPlan: 'free',
  unreadNotifications: 2,
);

void main() {
  late MockGetDashboardUseCase getDashboard;
  late MockDashboardRepository repository;

  setUp(() {
    getDashboard = MockGetDashboardUseCase();
    repository = MockDashboardRepository();
  });

  DashboardBloc _bloc() => DashboardBloc(
        getDashboard: getDashboard,
        repository: repository,
      );

  group('DashboardLoadRequested', () {
    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] on success',
      build: _bloc,
      setUp: () {
        when(() => getDashboard()).thenAnswer((_) async => Right(_dashboard));
      },
      act: (bloc) => bloc.add(const DashboardLoadRequested()),
      expect: () => [
        const DashboardLoading(),
        DashboardLoaded(_dashboard),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] on failure',
      build: _bloc,
      setUp: () {
        when(() => getDashboard())
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      act: (bloc) => bloc.add(const DashboardLoadRequested()),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardError>(),
      ],
    );
  });
}
