import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthResponseEntity extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final UserEntity user;
  final bool isNewUser;

  const AuthResponseEntity({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.isNewUser = false,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, user, isNewUser];
}
