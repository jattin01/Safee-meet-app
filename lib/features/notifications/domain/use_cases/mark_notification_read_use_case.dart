import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository _repository;
  MarkNotificationReadUseCase(this._repository);

  Future<Either<Failure, void>> call(String notificationId) =>
      _repository.markAsRead(notificationId);
}
