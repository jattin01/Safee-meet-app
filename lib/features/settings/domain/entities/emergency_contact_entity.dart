import 'package:equatable/equatable.dart';

class EmergencyContactEntity extends Equatable {
  final String id;
  final String fullName;
  final String? relationship;
  final String phoneNumber;

  const EmergencyContactEntity({
    required this.id,
    required this.fullName,
    this.relationship,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [id, fullName, relationship, phoneNumber];
}
