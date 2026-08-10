import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/dio_failure_mapper.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_search_repository.dart';
import '../remote_data_sources/member_search_remote_data_source.dart';

class MemberSearchRepositoryImpl implements MemberSearchRepository {
  final MemberSearchRemoteDataSource _remote;

  MemberSearchRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, MemberEntity>> searchByPIN(String pin) async {
    try {
      final data = await _remote.searchByPIN(pin);
      final failure = _businessFailure(data);
      if (failure != null) return Left(failure);
      return Right(_parse(data));
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
      final failure = _businessFailure(data);
      if (failure != null) return Left(failure);
      return Right(_parse(data));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // The search endpoints answer subscription/search-limit denials with HTTP
  // 200 and `success: false` in the body instead of a 4xx status — so no
  // DioException is ever thrown for them, and the body has to be checked
  // before treating it as a member record. `code: 'SUBSCRIPTION_REQUIRED'`
  // is how MemberSearchBloc tells this apart from an ordinary business
  // error to decide whether the error card links to the plans page.
  Failure? _businessFailure(Map<String, dynamic> data) {
    if (data['success'] != false) return null;
    final message = data['message'] as String? ??
        'Unable to search for this member right now.';
    return ServerFailure(
      message,
      code: data['subscription_required'] == true ? 'SUBSCRIPTION_REQUIRED' : null,
    );
  }

  @override
  Future<Either<Failure, List<MemberEntity>>> getRecentSearches() async {
    try {
      final data = await _remote.getRecentSearches();
      return Right(data.map(_parse).toList());
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  MemberEntity _parse(Map<String, dynamic> d) => MemberEntity(
        id: d['id'] as String,
        name: d['name'] as String,
        safeePIN: d['safeePIN'] as String,
        avatarUrl: d['avatarUrl'] as String?,
        trustScore: (d['trustScore'] as num).toInt(),
        verificationLevel: d['verificationLevel'] as String? ?? 'none',
        subscriptionPlan: d['subscriptionPlan'] as String? ?? 'free',
        safetyScore: (d['safetyScore'] as num?)?.toInt() ?? 0,
        totalMeetings: (d['totalMeetings'] as num?)?.toInt() ?? 0,
        badges: List<String>.from(d['badges'] as List? ?? []),
      );

  Failure _map(DioException e) {
    if (isConnectivityError(e)) return const NetworkFailure();
    if (e.response?.statusCode == 404) {
      return const ValidationFailure('Member not found');
    }
    return mapDioException(e);
  }
}
