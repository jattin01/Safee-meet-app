import 'package:equatable/equatable.dart';

enum MeetingStatus { scheduled, enRoute, arrived, completed, cancelled, pendingApproval, declined, incidentReported }
enum MeetingPurpose {
  coffee,
  marketplace,
  property,
  business,
  freelance,
  social,
  dating,
  other,
}

extension MeetingPurposeLabel on MeetingPurpose {
  String get label {
    switch (this) {
      case MeetingPurpose.coffee:
        return 'Coffee';
      case MeetingPurpose.marketplace:
        return 'Marketplace';
      case MeetingPurpose.property:
        return 'Property';
      case MeetingPurpose.business:
        return 'Business';
      case MeetingPurpose.freelance:
        return 'Freelance';
      case MeetingPurpose.social:
        return 'Social';
      case MeetingPurpose.dating:
        return 'Dating';
      case MeetingPurpose.other:
        return 'Other';
    }
  }
}

class MeetingEntity extends Equatable {
  final String id;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String partnerVerificationLevel;
  final DateTime scheduledAt;
  final MeetingPurpose purpose;
  final String location;
  final String? notes;
  final MeetingStatus status;
  final double? partnerLat;
  final double? partnerLng;
  final Duration? timeElapsed;
  final bool isHost;

  const MeetingEntity({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.partnerVerificationLevel,
    required this.scheduledAt,
    required this.purpose,
    required this.location,
    this.notes,
    required this.status,
    this.partnerLat,
    this.partnerLng,
    this.timeElapsed,
    required this.isHost,
  });

  MeetingEntity copyWith({MeetingStatus? status}) => MeetingEntity(
        id: id,
        partnerId: partnerId,
        partnerName: partnerName,
        partnerAvatarUrl: partnerAvatarUrl,
        partnerVerificationLevel: partnerVerificationLevel,
        scheduledAt: scheduledAt,
        purpose: purpose,
        location: location,
        notes: notes,
        status: status ?? this.status,
        partnerLat: partnerLat,
        partnerLng: partnerLng,
        timeElapsed: timeElapsed,
        isHost: isHost,
      );

  String get partnerInitials {
    final parts = partnerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';
  }

  int get statusIndex => status.index;

  @override
  List<Object?> get props => [
        id,
        partnerId,
        partnerName,
        scheduledAt,
        purpose,
        location,
        status,
        partnerLat,
        partnerLng,
        isHost,
      ];
}
