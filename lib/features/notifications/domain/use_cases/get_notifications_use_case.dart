import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  final NotificationsRepository _repository;
  GetNotificationsUseCase(this._repository);

  Future<Either<Failure, NotificationsPageEntity>> call({int page = 1}) =>
      _repository.getNotifications(page: page);
}
