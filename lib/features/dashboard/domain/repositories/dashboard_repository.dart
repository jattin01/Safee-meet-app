import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardEntity>> getDashboard();
  Future<Either<Failure, void>> toggleLocationSharing(bool enabled);
}
