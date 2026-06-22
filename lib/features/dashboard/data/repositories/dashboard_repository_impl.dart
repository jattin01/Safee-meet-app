import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../remote_data_sources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;
  DashboardRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, DashboardEntity>> getDashboard() async {
    try {
      final model = await _remote.getDashboard();
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_mapError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleLocationSharing(bool enabled) async {
    try {
      await _remote.toggleLocationSharing(enabled);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Failure _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    return ServerFailure(
      e.response?.data?['message'] as String? ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
