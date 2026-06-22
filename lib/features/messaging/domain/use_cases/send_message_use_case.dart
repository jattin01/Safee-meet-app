import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/messaging_repository.dart';

class SendMessageUseCase {
  final MessagingRepository _repository;
  SendMessageUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'text',
    String? attachmentUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
  }) =>
      _repository.sendMessage(
        roomId: roomId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        attachmentUrl: attachmentUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );
}
