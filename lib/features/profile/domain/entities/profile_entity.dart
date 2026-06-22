import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String safeePIN;
  final String? avatarUrl;
  final String? coverUrl;
  final int trustScore;
  final String verificationLevel;
  final String subscriptionPlan;
  final double rating;
  final int totalMeetings;
  final int totalReviews;
  final List<String> badges;
  final String? bio;
  final String? city;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.safeePIN,
    this.avatarUrl,
    this.coverUrl,
    required this.trustScore,
    required this.verificationLevel,
    required this.subscriptionPlan,
    required this.rating,
    required this.totalMeetings,
    required this.totalReviews,
    required this.badges,
    this.bio,
    this.city,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, name, safeePIN, trustScore, verificationLevel, subscriptionPlan];
}

class ReviewEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final double rating;
  final String text;
  final bool verifiedMeeting;
  final DateTime createdAt;
  final int helpfulCount;

  const ReviewEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.rating,
    required this.text,
    required this.verifiedMeeting,
    required this.createdAt,
    required this.helpfulCount,
  });

  String get authorInitials {
    final parts = authorName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, authorId, rating, text, createdAt];
}
