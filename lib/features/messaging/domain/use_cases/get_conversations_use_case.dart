import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

class GetConversationsUseCase {
  final MessagingRepository _repository;
  GetConversationsUseCase(this._repository);

  Future<Either<Failure, List<ConversationEntity>>> call(
    String currentUserId,
  ) =>
      _repository.getConversations(currentUserId);
}
