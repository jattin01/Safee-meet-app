import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/repositories/meetings_repository.dart';

class MeetingsRepositoryImpl implements MeetingsRepository {
  final ApiClient _api;
  MeetingsRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<MeetingEntity>>> getMeetings() async {
    try {
      final res = await _api.dio.get('/meetings');
      final list = (res.data as List<dynamic>)
          .map((e) => _parse(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MeetingEntity>> getMeeting(String id) async {
    try {
      final res = await _api.dio.get('/meetings/$id');
      return Right(_parse(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MeetingEntity>> scheduleMeeting({
    required String partnerId,
    required DateTime scheduledAt,
    required MeetingPurpose purpose,
    required String location,
    String? notes,
  }) async {
    try {
      final res = await _api.dio.post('/meetings', data: {
        'partnerId': partnerId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'purpose': purpose.name,
        'location': location,
        if (notes != null) 'notes': notes,
      });
      return Right(_parse(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MeetingEntity>> updateMeetingStatus({
    required String meetingId,
    required MeetingStatus status,
  }) async {
    try {
      final res = await _api.dio.patch('/meetings/$meetingId/status',
          data: {'status': status.name});
      return Right(_parse(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> endMeeting(String meetingId) async {
    try {
      await _api.dio.post('/meetings/$meetingId/end');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  MeetingEntity _parse(Map<String, dynamic> d) {
    final purposeStr = d['purpose'] as String? ?? 'other';
    final statusStr = d['status'] as String? ?? 'scheduled';
    final purpose = MeetingPurpose.values.firstWhere(
      (p) => p.name == purposeStr,
      orElse: () => MeetingPurpose.other,
    );
    final status = MeetingStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => MeetingStatus.scheduled,
    );
    return MeetingEntity(
      id: d['id'] as String,
      partnerId: d['partnerId'] as String,
      partnerName: d['partnerName'] as String,
      partnerAvatarUrl: d['partnerAvatarUrl'] as String?,
      partnerVerificationLevel: d['partnerVerificationLevel'] as String? ?? 'none',
      scheduledAt: DateTime.parse(d['scheduledAt'] as String),
      purpose: purpose,
      location: d['location'] as String,
      notes: d['notes'] as String?,
      status: status,
      partnerLat: (d['partnerLat'] as num?)?.toDouble(),
      partnerLng: (d['partnerLng'] as num?)?.toDouble(),
    );
  }

  Failure _map(DioException e) {
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
