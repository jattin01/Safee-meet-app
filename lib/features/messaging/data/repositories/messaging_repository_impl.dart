import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/chat_room_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final ChatRemoteDataSource _dataSource;
  final SecureStorageService _session;

  MessagingRepositoryImpl(this._dataSource, this._session);

  @override
  Future<Either<Failure, ChatRoomEntity>> createOrGetRoom({
    required String currentUserId,
    required String partnerId,
    required String currentUserName,
    required String partnerName,
    String? currentUserAvatarUrl,
    String? partnerAvatarUrl,
  }) async {
    try {
      final room = await _dataSource.createOrGetRoom(
        currentUserId: currentUserId,
        partnerId: partnerId,
        currentUserName: currentUserName,
        partnerName: partnerName,
        currentUserAvatarUrl: currentUserAvatarUrl,
        partnerAvatarUrl: partnerAvatarUrl,
      );
      return Right(room);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  ConversationEntity _roomToConversation(dynamic room, String currentUserId) {
    final partnerId = room.partnerIdFor(currentUserId);
    return ConversationEntity(
      id: room.roomId,
      partnerId: partnerId,
      partnerName: room.partnerNameFor(currentUserId),
      partnerAvatarUrl: room.partnerAvatarFor(currentUserId),
      partnerVerificationLevel: 'none',
      lastMessage: room.lastMessage.isNotEmpty
          ? MessageEntity(
              id: '',
              conversationId: room.roomId,
              senderId: '',
              content: room.lastMessage,
              type: MessageType.text,
              status: MessageStatus.sent,
              createdAt: room.lastMessageTime ?? room.createdAt,
            )
          : null,
      unreadCount: room.unreadCountFor(currentUserId),
      updatedAt: room.lastMessageTime ?? room.createdAt,
      isPinned: room.isPinnedBy(currentUserId),
      isMuted: room.isMutedBy(currentUserId),
    );
  }

  @override
  Stream<List<ConversationEntity>> conversationsStream(String userId) {
    return _dataSource.streamConversations(userId).map(
          (rooms) => rooms.map((r) => _roomToConversation(r, userId)).toList(),
        );
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations(
    String currentUserId,
  ) async {
    try {
      final rooms = await _dataSource.getConversations(currentUserId);
      return Right(rooms.map((r) => _roomToConversation(r, currentUserId)).toList());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'text',
    String? attachmentUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
  }) async {
    try {
      await _dataSource.sendMessage(
        roomId: roomId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        attachmentUrl: attachmentUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Stream<List<MessageEntity>> messageStream(String roomId) {
    return _dataSource
        .streamMessages(roomId)
        .map((models) => models.map((m) => m.toEntity(roomId)).toList());
  }

  @override
  Stream<List<MessageEntity>> messageStreamWithLimit(String roomId, int limit) {
    return _dataSource
        .streamMessagesWithLimit(roomId, limit)
        .map((models) => models.map((m) => m.toEntity(roomId)).toList());
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> fetchOlderMessages({
    required String roomId,
    required DateTime before,
  }) async {
    try {
      final models = await _dataSource.fetchOlderMessages(
        roomId: roomId,
        before: before,
      );
      return Right(models.map((m) => m.toEntity(roomId)).toList());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Stream<UploadProgress> uploadAttachment({
    required String roomId,
    required File file,
    required String fileName,
    String? mimeType,
  }) {
    return _dataSource.uploadFile(
      roomId: roomId,
      file: file,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    try {
      await _dataSource.updateReadStatus(
        roomId: roomId,
        currentUserId: currentUserId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<UserProfileEntity>>> getUsers(
      String excludeUid) async {
    try {
      final users = await _dataSource.getUsers(excludeUid);
      return Right(users);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> setTyping({
    required String roomId,
    required bool isTyping,
  }) async {
    try {
      final uid = await _session.getUserId();
      if (uid == null) return const Right(null);
      await _dataSource.setTyping(roomId: roomId, uid: uid, isTyping: isTyping);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Stream<bool> partnerTypingStream(String roomId, String partnerUid) {
    return _dataSource.streamPartnerTyping(
      roomId: roomId,
      partnerUid: partnerUid,
    );
  }

  @override
  Future<Either<Failure, void>> updatePresence(bool isOnline) async {
    try {
      final uid = await _session.getUserId();
      if (uid == null) return const Right(null);
      await _dataSource.updatePresence(uid: uid, isOnline: isOnline);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Stream<Map<String, dynamic>?> userPresenceStream(String partnerUid) {
    return _dataSource.streamUserPresence(partnerUid);
  }

  @override
  Future<Either<Failure, void>> togglePin({
    required String roomId,
    required bool pin,
  }) async {
    try {
      final uid = await _session.getUserId();
      if (uid == null) return const Right(null);
      await _dataSource.togglePin(roomId: roomId, uid: uid, pin: pin);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMute({
    required String roomId,
    required bool mute,
  }) async {
    try {
      final uid = await _session.getUserId();
      if (uid == null) return const Right(null);
      await _dataSource.toggleMute(roomId: roomId, uid: uid, mute: mute);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> respondToMeetingInvite({
    required String meetingId,
    required bool accepted,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncUserProfile({
    required String name,
    String? avatarUrl,
  }) async {
    try {
      final uid = await _session.getUserId();
      if (uid == null) return const Right(null);
      await _dataSource.syncUserProfile(
        uid: uid,
        name: name,
        avatarUrl: avatarUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  // This backend talks to Firestore/Storage directly (no Dio/REST here), so
  // failures surface as FirebaseException/SocketException rather than
  // DioException — map the connectivity-flavored codes to NetworkFailure
  // instead of leaking a raw `e.toString()` (e.g.
  // "[cloud_firestore/unavailable] Failed to get document...") to the UI.
  Failure _mapError(Object e) {
    if (e is FirebaseException) {
      if (e.code == 'unavailable' ||
          e.code == 'deadline-exceeded' ||
          e.code == 'network-request-failed') {
        return const NetworkFailure();
      }
      return ServerFailure(e.message ?? 'Something went wrong.', code: e.code);
    }
    if (e is SocketException) return const NetworkFailure();
    return const UnknownFailure();
  }
}
