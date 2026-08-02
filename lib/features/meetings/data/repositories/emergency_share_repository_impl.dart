import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/dio_failure_mapper.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/emergency_share_entity.dart';
import '../../domain/repositories/emergency_share_repository.dart';
import '../remote_data_sources/emergency_share_remote_data_source.dart';

class EmergencyShareRepositoryImpl implements EmergencyShareRepository {
  final EmergencyShareRemoteDataSource _remote;
  final SecureStorageService _storage;
  EmergencyShareRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, EmergencyShareEntity>> getEmergencyShare(
      String meetingId) async {
    try {
      final body = await _remote.getEmergencyShare(meetingId);

      final success = body['success'] as bool? ?? false;
      if (!success) {
        return Left(ServerFailure(
          body['message'] as String? ??
              'Unable to load emergency share details.',
        ));
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        return const Left(UnknownFailure());
      }

      final currentUserId = await _storage.getUserId();
      return Right(_parse(data, currentUserId));
    } on DioException catch (e, st) {
      debugPrint('[EmergencyShare] Request failed for meeting $meetingId: $e');
      debugPrintStack(stackTrace: st);
      return Left(_map(e));
    } catch (e, st) {
      debugPrint('[EmergencyShare] Unexpected error for meeting $meetingId: $e');
      debugPrintStack(stackTrace: st);
      return const Left(UnknownFailure());
    }
  }

  EmergencyShareEntity _parse(Map<String, dynamic> d, String? currentUserId) {
    final meetingJson = d['meeting'] as Map<String, dynamic>? ?? const {};
    final usersJson = d['users'] as Map<String, dynamic>? ?? const {};
    final hostJson = usersJson['host'] as Map<String, dynamic>? ?? const {};
    final guestJson = usersJson['guest'] as Map<String, dynamic>? ?? const {};
    final contactsJson = d['emergency_contacts'] as List<dynamic>? ?? const [];

    final host = _parseUser(hostJson);
    final guest = _parseUser(guestJson);
    final isHost = currentUserId != null && currentUserId == host.id;

    return EmergencyShareEntity(
      meeting: EmergencyShareMeetingEntity(
        id: meetingJson['id']?.toString() ?? '',
        reference: meetingJson['reference']?.toString() ?? '',
        status: meetingJson['status']?.toString() ?? 'unknown',
        meetingDate: meetingJson['meeting_date']?.toString() ?? '',
        meetingTime: meetingJson['meeting_time']?.toString() ?? '',
        location: meetingJson['location']?.toString() ?? '',
        latitude: _toDouble(meetingJson['latitude']),
        longitude: _toDouble(meetingJson['longitude']),
        purpose: meetingJson['purpose'] as String?,
      ),
      host: host,
      guest: guest,
      partner: isHost ? guest : host,
      emergencyContacts: contactsJson
          .map((c) => _parseContact(c as Map<String, dynamic>))
          .toList(),
    );
  }

  EmergencyShareUserEntity _parseUser(Map<String, dynamic> d) {
    return EmergencyShareUserEntity(
      id: d['id']?.toString() ?? '',
      name: d['name']?.toString() ?? 'SAFEE User',
      phone: d['phone'] as String?,
      latitude: _toDouble(d['latitude']),
      longitude: _toDouble(d['longitude']),
    );
  }

  EmergencyShareContactEntity _parseContact(Map<String, dynamic> d) {
    return EmergencyShareContactEntity(
      id: d['id']?.toString() ?? '',
      fullName: d['full_name']?.toString() ?? 'Unknown',
      relationship: d['relationship'] as String?,
      phoneNumber: d['phone_number'] as String?,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Failure _map(DioException e) {
    if (isConnectivityError(e)) return const NetworkFailure();
    if (e.response?.statusCode == 404) {
      final responseData = e.response?.data;
      final message =
          responseData is Map ? responseData['message'] as String? : null;
      return ServerFailure(message ?? 'Meeting not found.', statusCode: 404);
    }
    return mapDioException(e);
  }
}
