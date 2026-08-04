import '../../domain/entities/auth_response_entity.dart';
import 'user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel user;
  final bool isNewUser;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.isNewUser = false,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponseModel(
      accessToken:  data['accessToken']  as String,
      refreshToken: data['refreshToken'] as String?,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      isNewUser: data['isNewUser'] as bool? ?? false,
    );
  }

  AuthResponseEntity toEntity() => AuthResponseEntity(
        accessToken:  accessToken,
        refreshToken: refreshToken,
        user: user.toEntity(),
        isNewUser: isNewUser,
      );
}
