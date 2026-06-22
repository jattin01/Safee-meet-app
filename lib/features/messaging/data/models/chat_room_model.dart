import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room_entity.dart';

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.roomId,
    required super.participants,
    required super.lastMessage,
    super.lastMessageTime,
    required super.createdAt,
    required super.isBlocked,
    super.blockedBy,
    required super.participantNames,
    required super.participantAvatars,
    required super.unreadCounts,
    super.pinnedBy = const [],
    super.mutedBy = const [],
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    DateTime? lastMsgTime;
    final rawLast = json['lastMessageTime'];
    if (rawLast is Timestamp) {
      lastMsgTime = rawLast.toDate();
    } else if (rawLast is String) {
      lastMsgTime = DateTime.tryParse(rawLast);
    }

    DateTime createdAt;
    final rawCreated = json['createdAt'];
    if (rawCreated is Timestamp) {
      createdAt = rawCreated.toDate();
    } else {
      createdAt = DateTime.now();
    }

    final namesRaw = (json['participantNames'] as Map<String, dynamic>?) ?? {};
    final avatarsRaw = (json['participantAvatars'] as Map<String, dynamic>?) ?? {};
    final unreadRaw = (json['unreadCounts'] as Map<String, dynamic>?) ?? {};

    return ChatRoomModel(
      roomId: json['roomId'] as String? ?? '',
      participants: List<String>.from((json['participants'] as List?) ?? []),
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: lastMsgTime,
      createdAt: createdAt,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedBy: json['blockedBy'] as String?,
      participantNames:
          namesRaw.map((k, v) => MapEntry(k, (v as String?) ?? '')),
      participantAvatars:
          avatarsRaw.map((k, v) => MapEntry(k, v as String?)),
      unreadCounts:
          unreadRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      pinnedBy: List<String>.from((json['pinnedBy'] as List?) ?? []),
      mutedBy: List<String>.from((json['mutedBy'] as List?) ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime != null
            ? Timestamp.fromDate(lastMessageTime!)
            : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'isBlocked': isBlocked,
        'blockedBy': blockedBy,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'unreadCounts': unreadCounts,
        'pinnedBy': pinnedBy,
        'mutedBy': mutedBy,
      };

  ChatRoomModel copyWith({
    String? roomId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    bool? isBlocked,
    String? blockedBy,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
    Map<String, int>? unreadCounts,
    List<String>? pinnedBy,
    List<String>? mutedBy,
  }) =>
      ChatRoomModel(
        roomId: roomId ?? this.roomId,
        participants: participants ?? this.participants,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        createdAt: createdAt ?? this.createdAt,
        isBlocked: isBlocked ?? this.isBlocked,
        blockedBy: blockedBy ?? this.blockedBy,
        participantNames: participantNames ?? this.participantNames,
        participantAvatars: participantAvatars ?? this.participantAvatars,
        unreadCounts: unreadCounts ?? this.unreadCounts,
        pinnedBy: pinnedBy ?? this.pinnedBy,
        mutedBy: mutedBy ?? this.mutedBy,
      );
}
