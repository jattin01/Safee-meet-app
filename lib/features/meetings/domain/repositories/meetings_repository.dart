import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/meeting_entity.dart';

abstract class MeetingsRepository {
  Future<Either<Failure, List<MeetingEntity>>> getMeetings();
  Future<Either<Failure, MeetingEntity>> getMeeting(String id);
  Future<Either<Failure, MeetingEntity>> scheduleMeeting({
    required String partnerId,
    required DateTime scheduledAt,
    required MeetingPurpose purpose,
    required String location,
    String? notes,
  });
  Future<Either<Failure, MeetingEntity>> updateMeetingStatus({
    required String meetingId,
    required MeetingStatus status,
  });
  Future<Either<Failure, void>> endMeeting(String meetingId);
}
