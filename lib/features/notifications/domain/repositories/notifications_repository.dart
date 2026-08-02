import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, NotificationsPageEntity>> getNotifications({
    required int page,
  });

  Future<Either<Failure, void>> markAsRead(String notificationId);
}
