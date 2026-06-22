import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

class ListenMessagesUseCase {
  final MessagingRepository _repository;
  ListenMessagesUseCase(this._repository);

  Stream<List<MessageEntity>> call(String roomId) =>
      _repository.messageStream(roomId);
}
