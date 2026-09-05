import 'package:equatable/equatable.dart';

class MemberEntity extends Equatable {
  final String id;
  final String name;
  final String safeePIN;
  final String? avatarUrl;
  final int trustScore;
  final String verificationLevel;
  final String subscriptionPlan;
  final int safetyScore;
  final int totalMeetings;
  final List<String> badges;
  final String? badgeIcon;

  const MemberEntity({
    required this.id,
    required this.name,
    required this.safeePIN,
    this.avatarUrl,
    required this.trustScore,
    required this.verificationLevel,
    required this.subscriptionPlan,
    required this.safetyScore,
    required this.totalMeetings,
    required this.badges,
    this.badgeIcon,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isPremium => subscriptionPlan != 'free';

  @override
  List<Object?> get props => [id, name, safeePIN, avatarUrl, trustScore,
        verificationLevel, subscriptionPlan, safetyScore, totalMeetings, badges, badgeIcon];
}
