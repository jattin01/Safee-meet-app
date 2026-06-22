import 'package:equatable/equatable.dart';

class ChatRoomEntity extends Equatable {
  final String roomId;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final bool isBlocked;
  final String? blockedBy;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final Map<String, int> unreadCounts;
  final List<String> pinnedBy;
  final List<String> mutedBy;

  const ChatRoomEntity({
    required this.roomId,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    required this.isBlocked,
    this.blockedBy,
    required this.participantNames,
    required this.participantAvatars,
    required this.unreadCounts,
    this.pinnedBy = const [],
    this.mutedBy = const [],
  });

  String partnerIdFor(String currentUserId) =>
      participants.firstWhere((id) => id != currentUserId, orElse: () => '');

  String partnerNameFor(String currentUserId) =>
      participantNames[partnerIdFor(currentUserId)] ?? 'Unknown';

  String? partnerAvatarFor(String currentUserId) =>
      participantAvatars[partnerIdFor(currentUserId)];

  int unreadCountFor(String currentUserId) =>
      unreadCounts[currentUserId] ?? 0;

  bool isPinnedBy(String uid) => pinnedBy.contains(uid);

  bool isMutedBy(String uid) => mutedBy.contains(uid);

  @override
  List<Object?> get props => [
        roomId,
        participants,
        lastMessage,
        lastMessageTime,
        isBlocked,
        pinnedBy,
        mutedBy,
      ];
}
