import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/repositories/meetings_repository.dart';

class MeetingsRepositoryImpl implements MeetingsRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  MeetingsRepositoryImpl(this._api, this._storage);

  @override
  Future<Either<Failure, List<MeetingEntity>>> getMeetings() async {
    try {
      final res = await _api.dio.get('/v1/meetings');
      final body = res.data as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>? ?? []);
      final currentUserId = await _storage.getUserId();
      final meetings = list
          .map((e) => _parse(e as Map<String, dynamic>, currentUserId))
          .toList();
      return Right(meetings);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MeetingEntity>> getMeeting(String id) async {
    try {
      final res = await _api.dio.get('/v1/meetings/$id');
      final currentUserId = await _storage.getUserId();
      return Right(_parse(res.data as Map<String, dynamic>, currentUserId));
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
    double? latitude,
    double? longitude,
    String? notes,
    String? itemOrService,
  }) async {
    try {
      // The backend derives the host from the bearer token; only the guest
      // (the other party) is supplied here.
      final res = await _api.dio.post('/v1/meetings', data: {
        'guest_user_id': partnerId,
        'meeting_date': _formatDate(scheduledAt),
        'meeting_time': _formatTime(scheduledAt),
        'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null && notes.isNotEmpty) 'purpose': notes,
        if (itemOrService != null && itemOrService.isNotEmpty) 'item_or_service': itemOrService,
        'type': purpose.name,
      });

      final body = res.data as Map<String, dynamic>;
      final meetingId = (body['data'] as Map<String, dynamic>)['meeting_id'].toString();

      // The create response only carries the new id — fetch the full
      // record (with host/guest details) to populate the entity.
      return getMeeting(meetingId);
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
      switch (status) {
        case MeetingStatus.enRoute:
          await _api.dio.post('/v1/meetings/$meetingId/accept');
          break;
        case MeetingStatus.arrived:
          await _api.dio.post('/v1/meetings/$meetingId/arrive');
          break;
        case MeetingStatus.completed:
          await _api.dio.post('/v1/meetings/$meetingId/complete');
          break;
        case MeetingStatus.cancelled:
          await _api.dio.post('/v1/meetings/$meetingId/cancel');
          break;
        case MeetingStatus.scheduled:
        case MeetingStatus.pendingApproval:
        case MeetingStatus.declined:
          break;
      }
      return getMeeting(meetingId);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> endMeeting(String meetingId) async {
    try {
      await _api.dio.post('/v1/meetings/$meetingId/complete');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MeetingEntity>> approveMeeting(String meetingId) async {
    try {
      await _api.dio.post('/v1/meetings/$meetingId/approve');
      return getMeeting(meetingId);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, MeetingEntity>> denyMeeting(String meetingId) async {
    try {
      await _api.dio.post('/v1/meetings/$meetingId/deny');
      return getMeeting(meetingId);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  MeetingEntity _parse(Map<String, dynamic> d, String? currentUserId) {
    final hostId = d['host_user_id'] as String?;
    final guestId = d['guest_user_id'] as String?;
    final isHost = currentUserId != null && currentUserId == hostId;
    final partner = isHost ? d['guest'] as Map<String, dynamic>? : d['host'] as Map<String, dynamic>?;

    final typeStr = d['type'] as String? ?? 'other';
    final statusStr = d['status'] as String? ?? 'scheduled';
    final purpose = MeetingPurpose.values.firstWhere(
      (p) => p.name == typeStr,
      orElse: () => MeetingPurpose.other,
    );

    final meetingDate = d['meeting_date'] as String?;
    final meetingTime = d['meeting_time'] as String?;
    final scheduledAt = meetingDate != null
        ? DateTime.tryParse('$meetingDate ${meetingTime ?? '00:00:00'}') ?? DateTime.now()
        : DateTime.tryParse(d['scheduled_start_at'] as String? ?? '') ?? DateTime.now();

    return MeetingEntity(
      id: d['id'].toString(),
      partnerId: (isHost ? guestId : hostId) ?? '',
      partnerName: partner?['display_name'] as String? ?? 'SAFEE User',
      partnerAvatarUrl: partner?['avatar_url'] as String?,
      partnerVerificationLevel: partner?['trust_tier'] as String? ?? 'none',
      scheduledAt: scheduledAt,
      purpose: purpose,
      location: d['location'] as String? ?? '',
      notes: d['purpose'] as String?,
      status: _parseStatus(statusStr, d['arrived_at'] != null),
      partnerLat: _toDouble(d['latitude']),
      partnerLng: _toDouble(d['longitude']),
      isHost: isHost,
    );
  }

  MeetingStatus _parseStatus(String status, bool hasArrived) {
    switch (status) {
      case 'completed':
        return MeetingStatus.completed;
      case 'cancelled':
      case 'expired':
        return MeetingStatus.cancelled;
      case 'active':
      case 'live':
        return hasArrived ? MeetingStatus.arrived : MeetingStatus.enRoute;
      case 'pending_approval':
        return MeetingStatus.pendingApproval;
      case 'declined':
        return MeetingStatus.declined;
      default:
        return MeetingStatus.scheduled;
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Failure _map(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    final responseData = e.response?.data;
    final message = responseData is Map ? responseData['message'] as String? : null;

    if (status == 401 || status == 403) return const UnauthorizedFailure();
    if (status == 422) return ValidationFailure(message ?? 'Invalid meeting details.');
    return ServerFailure(message ?? 'Server error', statusCode: status);
  }
}
