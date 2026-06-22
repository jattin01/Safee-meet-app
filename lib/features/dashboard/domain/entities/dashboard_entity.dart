import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int trustScore;
  final String verificationLevel; // 'none' | 'level1' | 'level2' | 'professional'
  final bool isLocationSharing;
  final List<RecentMeetingEntity> recentMeetings;
  final String subscriptionPlan; // 'free' | 'basic' | 'premium' | 'professional'
  final int unreadNotifications;

  const DashboardEntity({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.trustScore,
    required this.verificationLevel,
    required this.isLocationSharing,
    required this.recentMeetings,
    required this.subscriptionPlan,
    required this.unreadNotifications,
  });

  String get firstName => name.split(' ').first;

  bool get isVerified => verificationLevel != 'none';

  bool get isFreeUser => subscriptionPlan == 'free';

  @override
  List<Object?> get props => [
        userId,
        name,
        avatarUrl,
        trustScore,
        verificationLevel,
        isLocationSharing,
        recentMeetings,
        subscriptionPlan,
        unreadNotifications,
      ];
}

class RecentMeetingEntity extends Equatable {
  final String id;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String partnerVerificationLevel;
  final DateTime scheduledAt;
  final String status; // 'scheduled' | 'active' | 'completed' | 'cancelled'
  final String purpose;
  final String? location;

  const RecentMeetingEntity({
    required this.id,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.partnerVerificationLevel,
    required this.scheduledAt,
    required this.status,
    required this.purpose,
    this.location,
  });

  bool get isUpcoming =>
      status == 'scheduled' && scheduledAt.isAfter(DateTime.now());

  String get partnerInitials {
    final parts = partnerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        id,
        partnerName,
        partnerAvatarUrl,
        partnerVerificationLevel,
        scheduledAt,
        status,
        purpose,
        location,
      ];
}
