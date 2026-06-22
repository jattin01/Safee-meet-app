import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/chat_room_entity.dart';
import '../repositories/messaging_repository.dart';

class CreateOrGetRoomUseCase {
  final MessagingRepository _repository;
  CreateOrGetRoomUseCase(this._repository);

  Future<Either<Failure, ChatRoomEntity>> call({
    required String currentUserId,
    required String partnerId,
    required String currentUserName,
    required String partnerName,
    String? currentUserAvatarUrl,
    String? partnerAvatarUrl,
  }) =>
      _repository.createOrGetRoom(
        currentUserId: currentUserId,
        partnerId: partnerId,
        currentUserName: currentUserName,
        partnerName: partnerName,
        currentUserAvatarUrl: currentUserAvatarUrl,
        partnerAvatarUrl: partnerAvatarUrl,
      );
}
