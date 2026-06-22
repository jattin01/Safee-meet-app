import 'dart:io';
import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

class UploadAttachmentUseCase {
  final MessagingRepository _repository;
  UploadAttachmentUseCase(this._repository);

  Stream<UploadProgress> call({
    required String roomId,
    required File file,
    required String fileName,
    String? mimeType,
  }) =>
      _repository.uploadAttachment(
        roomId: roomId,
        file: file,
        fileName: fileName,
        mimeType: mimeType,
      );
}
