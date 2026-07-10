import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/emergency_contact_entity.dart';

abstract class EmergencyContactRepository {
  Future<Either<Failure, List<EmergencyContactEntity>>> getContacts();

  Future<Either<Failure, EmergencyContactEntity>> addContact({
    required String fullName,
    required String relationship,
    required String phoneNumber,
  });

  Future<Either<Failure, void>> deleteContact(String contactId);
}
