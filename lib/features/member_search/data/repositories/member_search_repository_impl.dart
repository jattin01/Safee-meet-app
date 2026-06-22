import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_search_repository.dart';
import '../remote_data_sources/member_search_remote_data_source.dart';

class MemberSearchRepositoryImpl implements MemberSearchRepository {
  final MemberSearchRemoteDataSource _remote;
  final HiveService _hive;

  MemberSearchRepositoryImpl(this._remote, this._hive);

  @override
  Future<Either<Failure, MemberEntity>> searchByPIN(String pin) async {
    try {
      final data = await _remote.searchByPIN(pin);
      final entity = _parse(data);
      await _hive.cacheValue('recent_$pin', pin);
      return Right(entity);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MemberEntity>> searchByQR(String qrCode) async {
    try {
      final data = await _remote.searchByQR(qrCode);
      return Right(_parse(data));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRecentSearches() async {
    return const Right([]);
  }

  MemberEntity _parse(Map<String, dynamic> d) => MemberEntity(
        id: d['id'] as String,
        name: d['name'] as String,
        safeePIN: d['safeePIN'] as String,
        avatarUrl: d['avatarUrl'] as String?,
        trustScore: (d['trustScore'] as num).toInt(),
        verificationLevel: d['verificationLevel'] as String? ?? 'none',
        subscriptionPlan: d['subscriptionPlan'] as String? ?? 'free',
        rating: (d['rating'] as num?)?.toDouble() ?? 0,
        totalMeetings: (d['totalMeetings'] as num?)?.toInt() ?? 0,
        badges: List<String>.from(d['badges'] as List? ?? []),
      );

  Failure _map(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    if (status == 404) return const ValidationFailure('Member not found');
    return ServerFailure(
      e.response?.data?['message'] as String? ?? 'Server error',
      statusCode: status,
    );
  }
}
