import 'package:equatable/equatable.dart';

class EmergencyShareMeetingEntity extends Equatable {
  final String id;
  final String reference;
  final String status;
  final String meetingDate;
  final String meetingTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? purpose;

  const EmergencyShareMeetingEntity({
    required this.id,
    required this.reference,
    required this.status,
    required this.meetingDate,
    required this.meetingTime,
    required this.location,
    this.latitude,
    this.longitude,
    this.purpose,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        meetingDate,
        meetingTime,
        location,
        latitude,
        longitude,
        purpose,
      ];
}

class EmergencyShareUserEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;

  const EmergencyShareUserEntity({
    required this.id,
    required this.name,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, phone];
}

class EmergencyShareContactEntity extends Equatable {
  final String id;
  final String fullName;
  final String? relationship;
  final String? phoneNumber;

  const EmergencyShareContactEntity({
    required this.id,
    required this.fullName,
    this.relationship,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [id, fullName, relationship, phoneNumber];
}

class EmergencyShareEntity extends Equatable {
  final EmergencyShareMeetingEntity meeting;
  final EmergencyShareUserEntity host;
  final EmergencyShareUserEntity guest;
  final List<EmergencyShareContactEntity> emergencyContacts;

  const EmergencyShareEntity({
    required this.meeting,
    required this.host,
    required this.guest,
    required this.emergencyContacts,
  });

  @override
  List<Object?> get props => [meeting, host, guest, emergencyContacts];
}
