import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String safeePin;
  final int trustScore;
  final String verificationLevel; // 'none' | 'level1' | 'level2' | 'professional'
  final String plan; // 'free' | 'basic' | 'premium' | 'professional'
  final String? avatarUrl;
  final double safetyRating;
  final int meetingsCompleted;

  const UserEntity({
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

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  bool get isLevel1Verified =>
      verificationLevel == 'level1' ||
      verificationLevel == 'level2' ||
      verificationLevel == 'professional';

  bool get isLevel2Verified =>
      verificationLevel == 'level2' ||
      verificationLevel == 'professional';

  bool get isProfessionalVerified =>
      verificationLevel == 'professional';

  @override
  List<Object?> get props => [
        id, name, email, phone, safeePin,
        trustScore, verificationLevel, plan,
        avatarUrl, safetyRating, meetingsCompleted,
      ];
}
