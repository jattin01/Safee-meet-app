import 'package:equatable/equatable.dart';

/// Result of POST /v1/meetings/{meeting}/review.
class SubmittedReviewEntity extends Equatable {
  final int id;
  final String meetingId;
  final int reviewerId;
  final int revieweeId;
  final int rating;
  final String? comment;
  final bool punctual;
  final bool trustworthy;
  final bool responsive;
  final int helpfulCount;
  final DateTime? createdAt;

  const SubmittedReviewEntity({
    required this.id,
    required this.meetingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.punctual,
    required this.trustworthy,
    required this.responsive,
    required this.helpfulCount,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        meetingId,
        reviewerId,
        revieweeId,
        rating,
        comment,
        punctual,
        trustworthy,
        responsive,
        helpfulCount,
        createdAt,
      ];
}
