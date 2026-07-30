import 'package:equatable/equatable.dart';

enum VerificationStep { uploadId, selfie, processing, complete }

class VerificationEntity extends Equatable {
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? selfieUrl;
  final bool hasIdFront;
  final bool hasIdBack;
  final bool hasSelfie;
  final VerificationStep currentStep;
  final String
      status; // 'not_started' | 'draft' | 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;

  const VerificationEntity({
    this.idFrontUrl,
    this.idBackUrl,
    this.selfieUrl,
    required this.hasIdFront,
    required this.hasIdBack,
    required this.hasSelfie,
    required this.currentStep,
    required this.status,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        idFrontUrl,
        idBackUrl,
        selfieUrl,
        hasIdFront,
        hasIdBack,
        hasSelfie,
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

class VerificationSubmitEntity extends Equatable {
  final int id;
  final String userId;
  final String faceIdImage;
  final String nationalIdFrontImage;
  final String nationalIdBackImage;
  final String nationalIdNumber;
  final String nationalIdCountry;
  final int verificationLevel;
  final String status;

  const VerificationSubmitEntity({
    required this.id,
    required this.userId,
    required this.faceIdImage,
    required this.nationalIdFrontImage,
    required this.nationalIdBackImage,
    required this.nationalIdNumber,
    required this.nationalIdCountry,
    required this.verificationLevel,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        faceIdImage,
        nationalIdFrontImage,
        nationalIdBackImage,
        nationalIdNumber,
        nationalIdCountry,
        verificationLevel,
        status,
      ];
}

class VerificationSubmitResult extends Equatable {
  final String message;
  final VerificationSubmitEntity data;

  const VerificationSubmitResult({required this.message, required this.data});

  @override
  List<Object?> get props => [message, data];
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
