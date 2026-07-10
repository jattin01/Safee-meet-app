import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String safeeId;
  final String displayName;
  final String? avatarUrl;
  final String accountType;
  final String authProvider;
  final String status;
  final int trustScore;
  final String trustTier;
  final bool isChatEnabled;
  final bool isMeetingEnabled;
  final bool isSosEnabled;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;
  final String? lastLoginAt;
  final String? createdAt;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        safeeId: (json['safeeId'] ?? json['safee_id'] ?? '') as String,
        displayName: (json['displayName'] ??
            json['display_name'] ??
            json['name'] ??
            'SAFEE User') as String,
        avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
        accountType:
            (json['accountType'] ?? json['account_type'] ?? 'normal') as String,
        authProvider: (json['authProvider'] ?? json['auth_provider'] ?? 'phone')
            as String,
        status: (json['status'] ?? 'active') as String,
        trustScore:
            ((json['trustScore'] ?? json['trust_score']) as num?)?.toInt() ?? 0,
        trustTier:
            (json['trustTier'] ?? json['trust_tier'] ?? 'none') as String,
        isChatEnabled:
            (json['isChatEnabled'] ?? json['is_chat_enabled'] ?? true) as bool,
        isMeetingEnabled: (json['isMeetingEnabled'] ??
            json['is_meeting_enabled'] ??
            true) as bool,
        isSosEnabled:
            (json['isSosEnabled'] ?? json['is_sos_enabled'] ?? true) as bool,
        emailVerifiedAt:
            (json['emailVerifiedAt'] ?? json['email_verified_at']) as String?,
        phoneVerifiedAt:
            (json['phoneVerifiedAt'] ?? json['phone_verified_at']) as String?,
        lastLoginAt: (json['lastLoginAt'] ?? json['last_login_at']) as String?,
        createdAt: (json['createdAt'] ?? json['created_at']) as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'safeeId': safeeId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'accountType': accountType,
        'authProvider': authProvider,
        'status': status,
        'trustScore': trustScore,
        'trustTier': trustTier,
        'isChatEnabled': isChatEnabled,
        'isMeetingEnabled': isMeetingEnabled,
        'isSosEnabled': isSosEnabled,
        'emailVerifiedAt': emailVerifiedAt,
        'phoneVerifiedAt': phoneVerifiedAt,
        'lastLoginAt': lastLoginAt,
        'createdAt': createdAt,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        safeeId: safeeId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        accountType: accountType,
        authProvider: authProvider,
        status: status,
        trustScore: trustScore,
        trustTier: trustTier,
        isChatEnabled: isChatEnabled,
        isMeetingEnabled: isMeetingEnabled,
        isSosEnabled: isSosEnabled,
        emailVerifiedAt: emailVerifiedAt,
        phoneVerifiedAt: phoneVerifiedAt,
        lastLoginAt: lastLoginAt,
        createdAt: createdAt,
      );

  static UserModel fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        safeeId: entity.safeeId,
        displayName: entity.displayName,
        avatarUrl: entity.avatarUrl,
        accountType: entity.accountType,
        authProvider: entity.authProvider,
        status: entity.status,
        trustScore: entity.trustScore,
        trustTier: entity.trustTier,
        isChatEnabled: entity.isChatEnabled,
        isMeetingEnabled: entity.isMeetingEnabled,
        isSosEnabled: entity.isSosEnabled,
        emailVerifiedAt: entity.emailVerifiedAt,
        phoneVerifiedAt: entity.phoneVerifiedAt,
        lastLoginAt: entity.lastLoginAt,
        createdAt: entity.createdAt,
      );
}
