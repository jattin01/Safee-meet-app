import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
