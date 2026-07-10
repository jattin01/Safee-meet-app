import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String  id;
  final String  safeeId;
  final String  displayName;
  final String? avatarUrl;
  final String  accountType;
  final String  authProvider;
  final String  status;
  final int     trustScore;
  final String  trustTier;
  final bool    isChatEnabled;
  final bool    isMeetingEnabled;
  final bool    isSosEnabled;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;
  final String? lastLoginAt;
  final String? createdAt;

  const UserEntity({
    required this.id,
    required this.safeeId,
    required this.displayName,
    this.avatarUrl,
    required this.accountType,
    required this.authProvider,
    required this.status,
    required this.trustScore,
    required this.trustTier,
    required this.isChatEnabled,
    required this.isMeetingEnabled,
    required this.isSosEnabled,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.lastLoginAt,
    this.createdAt,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  bool get isVerified => emailVerifiedAt != null || phoneVerifiedAt != null;

  @override
  List<Object?> get props => [
        id, safeeId, displayName, avatarUrl,
        accountType, authProvider, status,
        trustScore, trustTier,
        isChatEnabled, isMeetingEnabled, isSosEnabled,
        emailVerifiedAt, phoneVerifiedAt, lastLoginAt, createdAt,
      ];
}
