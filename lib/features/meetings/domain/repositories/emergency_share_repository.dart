import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/emergency_share_entity.dart';

abstract class EmergencyShareRepository {
  Future<Either<Failure, EmergencyShareEntity>> getEmergencyShare(
      String meetingId);
}
