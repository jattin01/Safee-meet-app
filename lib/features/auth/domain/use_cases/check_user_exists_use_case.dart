import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/auth_repository.dart';

class CheckUserExistsUseCase {
  final AuthRepository _repository;
  const CheckUserExistsUseCase(this._repository);

  Future<Either<Failure, bool>> call(CheckUserExistsParams params) =>
      _repository.checkUserExists(
        email: params.email,
        phone: params.phone,
        providerUid: params.providerUid,
      );
}

class CheckUserExistsParams extends Equatable {
  final String? email;
  final String? phone;
  final String? providerUid;

  const CheckUserExistsParams({this.email, this.phone, this.providerUid});

  @override
  List<Object?> get props => [email, phone, providerUid];
}
