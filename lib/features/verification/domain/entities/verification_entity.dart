import 'package:equatable/equatable.dart';

enum VerificationStep { uploadId, selfie, processing, complete }

class VerificationStatusEntity extends Equatable {
  final int trustScore;
  final String verificationLevel;
  final bool level1Complete;
  final bool level2Complete;
  final bool professionalComplete;
  final String kycStatus;
  final VerificationStep currentStep;
  final String? rejectionReason;
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
    required this.kycStatus,
    required this.currentStep,
    this.rejectionReason,
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
        kycStatus,
        currentStep,
        rejectionReason,
        safetyMetricMeetings,
        safetyMetricResponsiveness,
        safetyMetricReviews,
        recentReviews,
      ];
}

/// Short-lived token handed to `DiditSdk.startVerification` to launch the
/// native capture UI (ID scan + facial liveness) — minted by our backend via
/// Didit's `POST /v3/session/`, which requires the secret API key that must
/// never reach the client.
class DiditSessionEntity extends Equatable {
  final String sessionId;
  final String sessionToken;

  const DiditSessionEntity({
    required this.sessionId,
    required this.sessionToken,
  });

  @override
  List<Object?> get props => [sessionId, sessionToken];
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
