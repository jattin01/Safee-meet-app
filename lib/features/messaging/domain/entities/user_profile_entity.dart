import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String uid;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? phone;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserProfileEntity({
    required this.uid,
    required this.name,
    this.email,
    this.avatarUrl,
    this.phone,
    this.isOnline = false,
    this.lastSeen,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    DateTime? lastSeen;
    final rawLastSeen = json['lastSeen'];
    if (rawLastSeen is Timestamp) {
      lastSeen = rawLastSeen.toDate();
    }
    return UserProfileEntity(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'isOnline': isOnline,
        'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      };

  @override
  List<Object?> get props => [uid, name, email, avatarUrl, isOnline, lastSeen];
}
