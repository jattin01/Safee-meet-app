import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/messaging_repository.dart';

class MarkMessageReadUseCase {
  final MessagingRepository _repository;
  MarkMessageReadUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String roomId,
    required String currentUserId,
  }) =>
      _repository.markAsRead(roomId: roomId, currentUserId: currentUserId);
}
