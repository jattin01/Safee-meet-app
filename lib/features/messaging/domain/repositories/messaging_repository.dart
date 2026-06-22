import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/chat_room_entity.dart';
import '../entities/message_entity.dart';
import '../entities/user_profile_entity.dart';

abstract class MessagingRepository {
  // ── Room ──────────────────────────────────────────────────────────────────
  Future<Either<Failure, ChatRoomEntity>> createOrGetRoom({
    required String currentUserId,
    required String partnerId,
    required String currentUserName,
    required String partnerName,
    String? currentUserAvatarUrl,
    String? partnerAvatarUrl,
  });

  // ── Conversations list ────────────────────────────────────────────────────
  Future<Either<Failure, List<ConversationEntity>>> getConversations(
    String currentUserId,
  );

  Stream<List<ConversationEntity>> conversationsStream(String userId);

  // ── Messages ──────────────────────────────────────────────────────────────
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String content,
    String type,
    String? attachmentUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
  });

  Stream<List<MessageEntity>> messageStream(String roomId);

  Stream<List<MessageEntity>> messageStreamWithLimit(String roomId, int limit);

  Future<Either<Failure, List<MessageEntity>>> fetchOlderMessages({
    required String roomId,
    required DateTime before,
  });

  // ── Attachment upload ─────────────────────────────────────────────────────
  Stream<UploadProgress> uploadAttachment({
    required String roomId,
    required File file,
    required String fileName,
    String? mimeType,
  });

  // ── Read receipts ─────────────────────────────────────────────────────────
  Future<Either<Failure, void>> markAsRead({
    required String roomId,
    required String currentUserId,
  });

  // ── User discovery ────────────────────────────────────────────────────────
  Future<Either<Failure, List<UserProfileEntity>>> getUsers(String excludeUid);

  // ── Typing indicator ──────────────────────────────────────────────────────
  Future<Either<Failure, void>> setTyping({
    required String roomId,
    required bool isTyping,
  });

  Stream<bool> partnerTypingStream(String roomId, String partnerUid);

  // ── Presence ──────────────────────────────────────────────────────────────
  Future<Either<Failure, void>> updatePresence(bool isOnline);

  Stream<Map<String, dynamic>?> userPresenceStream(String partnerUid);

  // ── Pin / Mute ────────────────────────────────────────────────────────────
  Future<Either<Failure, void>> togglePin({
    required String roomId,
    required bool pin,
  });

  Future<Either<Failure, void>> toggleMute({
    required String roomId,
    required bool mute,
  });

  // ── Phase 2+ ──────────────────────────────────────────────────────────────
  Future<Either<Failure, void>> respondToMeetingInvite({
    required String meetingId,
    required bool accepted,
  });
}
