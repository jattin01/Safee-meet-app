import 'package:equatable/equatable.dart';

enum VerificationStep { uploadId, selfie, processing, complete }

class VerificationEntity extends Equatable {
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? selfieUrl;
  final VerificationStep currentStep;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;

  const VerificationEntity({
    this.idFrontUrl,
    this.idBackUrl,
    this.selfieUrl,
    required this.currentStep,
    required this.status,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        idFrontUrl,
        idBackUrl,
        selfieUrl,
        currentStep,
        status,
        rejectionReason,
      ];
}

class VerificationStatusEntity extends Equatable {
  final int trustScore;
  final String verificationLevel;
  final bool level1Complete;
  final bool level2Complete;
  final bool professionalComplete;
  final double safetyMetricMeetings;
  final double safetyMetricResponsiveness;
  final double safetyMetricReviews;
  final List<ReviewSummaryEntity> recentReviews;

  const VerificationStatusEntity({
    required this.trustScore,
    required this.verificationLevel,
    required this.level1Complete,
    required this.level2Complete,
    required this.professionalComplete,
    required this.safetyMetricMeetings,
    required this.safetyMetricResponsiveness,
    required this.safetyMetricReviews,
    required this.recentReviews,
  });

  @override
  List<Object?> get props => [
        trustScore,
        verificationLevel,
        level1Complete,
        level2Complete,
        professionalComplete,
        safetyMetricMeetings,
        safetyMetricResponsiveness,
        safetyMetricReviews,
        recentReviews,
      ];
}

class ReviewSummaryEntity extends Equatable {
  final String authorName;
  final double rating;
  final String text;
  final DateTime createdAt;

  const ReviewSummaryEntity({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [authorName, rating, text, createdAt];
}
