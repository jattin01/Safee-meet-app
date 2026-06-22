import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String safeePin;
  final int trustScore;
  final String verificationLevel;
  final String plan;
  final String? avatarUrl;
  final double safetyRating;
  final int meetingsCompleted;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.safeePin,
    required this.trustScore,
    required this.verificationLevel,
    required this.plan,
    this.avatarUrl,
    required this.safetyRating,
    required this.meetingsCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        safeePin: (json['safee_pin'] ?? json['safeePin']) as String,
        trustScore:
            ((json['trust_score'] ?? json['trustScore']) as num?)?.toInt() ?? 0,
        verificationLevel: (json['verification_level'] ??
                json['verificationLevel'] ??
                'none') as String,
        plan: json['plan'] as String? ?? 'free',
        avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
        safetyRating:
            ((json['safety_rating'] ?? json['safetyRating']) as num?)
                    ?.toDouble() ??
                0.0,
        meetingsCompleted:
            ((json['meetings_completed'] ?? json['meetingsCompleted']) as num?)
                    ?.toInt() ??
                0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'safee_pin': safeePin,
        'trust_score': trustScore,
        'verification_level': verificationLevel,
        'plan': plan,
        'avatar_url': avatarUrl,
        'safety_rating': safetyRating,
        'meetings_completed': meetingsCompleted,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
        phone: phone,
        safeePin: safeePin,
        trustScore: trustScore,
        verificationLevel: verificationLevel,
        plan: plan,
        avatarUrl: avatarUrl,
        safetyRating: safetyRating,
        meetingsCompleted: meetingsCompleted,
      );

  static UserModel fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        name: entity.name,
        email: entity.email,
        phone: entity.phone,
        safeePin: entity.safeePin,
        trustScore: entity.trustScore,
        verificationLevel: entity.verificationLevel,
        plan: entity.plan,
        avatarUrl: entity.avatarUrl,
        safetyRating: entity.safetyRating,
        meetingsCompleted: entity.meetingsCompleted,
      );
}
