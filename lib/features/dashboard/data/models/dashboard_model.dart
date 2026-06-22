import '../../domain/entities/dashboard_entity.dart';

class DashboardModel {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int trustScore;
  final String verificationLevel;
  final bool isLocationSharing;
  final List<RecentMeetingModel> recentMeetings;
  final String subscriptionPlan;
  final int unreadNotifications;

  const DashboardModel({
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

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        userId: json['userId'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        trustScore: (json['trustScore'] as num).toInt(),
        verificationLevel: json['verificationLevel'] as String? ?? 'none',
        isLocationSharing: json['isLocationSharing'] as bool? ?? false,
        recentMeetings: (json['recentMeetings'] as List<dynamic>? ?? [])
            .map((e) => RecentMeetingModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        subscriptionPlan: json['subscriptionPlan'] as String? ?? 'free',
        unreadNotifications: (json['unreadNotifications'] as num?)?.toInt() ?? 0,
      );

  DashboardEntity toEntity() => DashboardEntity(
        userId: userId,
        name: name,
        avatarUrl: avatarUrl,
        trustScore: trustScore,
        verificationLevel: verificationLevel,
        isLocationSharing: isLocationSharing,
        recentMeetings: recentMeetings.map((m) => m.toEntity()).toList(),
        subscriptionPlan: subscriptionPlan,
        unreadNotifications: unreadNotifications,
      );
}

class RecentMeetingModel {
  final String id;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String partnerVerificationLevel;
  final String scheduledAt;
  final String status;
  final String purpose;
  final String? location;

  const RecentMeetingModel({
    required this.id,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.partnerVerificationLevel,
    required this.scheduledAt,
    required this.status,
    required this.purpose,
    this.location,
  });

  factory RecentMeetingModel.fromJson(Map<String, dynamic> json) => RecentMeetingModel(
        id: json['id'] as String,
        partnerName: json['partnerName'] as String,
        partnerAvatarUrl: json['partnerAvatarUrl'] as String?,
        partnerVerificationLevel: json['partnerVerificationLevel'] as String? ?? 'none',
        scheduledAt: json['scheduledAt'] as String,
        status: json['status'] as String,
        purpose: json['purpose'] as String,
        location: json['location'] as String?,
      );

  RecentMeetingEntity toEntity() => RecentMeetingEntity(
        id: id,
        partnerName: partnerName,
        partnerAvatarUrl: partnerAvatarUrl,
        partnerVerificationLevel: partnerVerificationLevel,
        scheduledAt: DateTime.parse(scheduledAt),
        status: status,
        purpose: purpose,
        location: location,
      );
}
