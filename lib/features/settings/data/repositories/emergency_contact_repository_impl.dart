import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../remote_data_sources/emergency_contact_remote_data_source.dart';

class EmergencyContactRepositoryImpl implements EmergencyContactRepository {
  final EmergencyContactRemoteDataSource _remote;

  EmergencyContactRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<EmergencyContactEntity>>> getContacts() async {
    try {
      final data = await _remote.getContacts();
      return Right(data.map(_parse).toList());
    } on DioException catch (e) {
      // Backend returns 404 with an empty list rather than [] when a user
      // has no emergency contacts yet — treat that as an empty list, not an error.
      if (e.response?.statusCode == 404) {
        return const Right([]);
      }
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, EmergencyContactEntity>> addContact({
    required String fullName,
    required String relationship,
    required String phoneNumber,
  }) async {
    try {
      final data = await _remote.addContact({
        'full_name': fullName,
        'relationship': relationship,
        'phone_number': phoneNumber,
      });
      return Right(_parse(data));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteContact(String contactId) async {
    try {
      await _remote.deleteContact(contactId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  EmergencyContactEntity _parse(Map<String, dynamic> d) => EmergencyContactEntity(
        id: d['id'].toString(),
        fullName: d['full_name'] as String? ?? '',
        relationship: d['relationship'] as String?,
        phoneNumber: d['phone_number'] as String? ?? '',
      );

  Failure _map(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    final responseData = e.response?.data;
    final message = responseData is Map ? responseData['message'] as String? : null;

    if (status == 401 || status == 403) return const UnauthorizedFailure();
    if (status == 404) return ValidationFailure(message ?? 'Emergency contact not found.');
    if (status == 409) return ValidationFailure(message ?? 'This phone number already exists.');
    if (status == 422) return ValidationFailure(message ?? 'Invalid emergency contact details.');
    return ServerFailure(message ?? 'Server error', statusCode: status);
  }
}
