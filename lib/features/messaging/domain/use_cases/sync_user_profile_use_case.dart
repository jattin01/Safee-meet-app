import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/messaging_repository.dart';

/// Keeps the messaging feature's own `users/{uid}` Firestore doc in sync
/// with the real, REST-backed profile name/avatar — see
/// ChatRemoteDataSource.syncUserProfile for the full "why".
class SyncUserProfileUseCase {
  final MessagingRepository _repository;
  SyncUserProfileUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String name,
    String? avatarUrl,
  }) =>
      _repository.syncUserProfile(name: name, avatarUrl: avatarUrl);
}
