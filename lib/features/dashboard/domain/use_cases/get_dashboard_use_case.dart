import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardUseCase {
  final DashboardRepository _repository;
  GetDashboardUseCase(this._repository);

  Future<Either<Failure, DashboardEntity>> call() => _repository.getDashboard();
}
