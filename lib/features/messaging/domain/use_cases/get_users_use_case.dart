import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/messaging_repository.dart';

class GetUsersUseCase {
  final MessagingRepository _repository;
  GetUsersUseCase(this._repository);

  Future<Either<Failure, List<UserProfileEntity>>> call(String excludeUid) =>
      _repository.getUsers(excludeUid);
}
