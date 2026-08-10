import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String safeePIN;
  final String? avatarUrl;
  final String? coverUrl;
  final String? phone;
  final String? email;
  final int trustScore;
  final String verificationLevel;
  /// Raw backend status: 'not_submitted' | 'pending' | 'approved' | 'rejected'.
  final String verificationStatus;
  final String subscriptionPlan;
  final int safetyScore;
  final int totalMeetings;
  final int totalReviews;
  final List<String> badges;
  final String? bio;
  final String? city;
  final String? status;
  final DateTime? createdAt;

  /// Number of unique members who have searched this user's Safee PIN/QR.
  final int pinSearchCount;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.safeePIN,
    this.avatarUrl,
    this.coverUrl,
    this.phone,
    this.email,
    required this.trustScore,
    required this.verificationLevel,
    this.verificationStatus = 'not_submitted',
    required this.subscriptionPlan,
    required this.safetyScore,
    required this.totalMeetings,
    required this.totalReviews,
    required this.badges,
    this.bio,
    this.city,
    this.status,
    this.createdAt,
    this.pinSearchCount = 0,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        safeePIN,
        phone,
        email,
        trustScore,
        verificationLevel,
        subscriptionPlan,
        status,
        createdAt,
        pinSearchCount,
      ];
}

class ReviewEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  // 'none' | 'level1' | 'level2' | 'professional' — the reviewer's own
  // verification level, as returned by GET /v1/reviews.
  final String authorVerificationLevel;
  final double rating;
  final String text;
  final bool verifiedMeeting;
  final String? meetingType;
  final bool punctual;
  final bool trustworthy;
  final bool responsive;
  final DateTime createdAt;
  final int helpfulCount;

  const ReviewEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorVerificationLevel = 'none',
    required this.rating,
    required this.text,
    required this.verifiedMeeting,
    this.meetingType,
    this.punctual = false,
    this.trustworthy = false,
    this.responsive = false,
    required this.createdAt,
    required this.helpfulCount,
  });

  String get authorInitials {
    final parts = authorName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
  }

  ReviewEntity copyWith({int? helpfulCount}) => ReviewEntity(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorVerificationLevel: authorVerificationLevel,
        rating: rating,
        text: text,
        verifiedMeeting: verifiedMeeting,
        meetingType: meetingType,
        punctual: punctual,
        trustworthy: trustworthy,
        responsive: responsive,
        createdAt: createdAt,
        helpfulCount: helpfulCount ?? this.helpfulCount,
      );

  @override
  List<Object?> get props => [
        id,
        authorId,
        rating,
        text,
        createdAt,
        authorVerificationLevel,
        meetingType,
        punctual,
        trustworthy,
        responsive,
        helpfulCount,
      ];
}
