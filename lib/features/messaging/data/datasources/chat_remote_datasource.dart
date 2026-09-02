import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatRoomModel> createOrGetRoom({
    required String currentUserId,
    required String partnerId,
    required String currentUserName,
    required String partnerName,
    String? currentUserAvatarUrl,
    String? partnerAvatarUrl,
  });

  Future<ChatRoomModel?> getRoom(String roomId);

  Future<MessageModel> sendMessage({
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

  Stream<UploadProgress> uploadFile({
    required String roomId,
    required File file,
    required String fileName,
    String? mimeType,
  });

  Stream<List<MessageModel>> streamMessages(String roomId);

  Stream<List<MessageModel>> streamMessagesWithLimit(String roomId, int limit);

  Future<List<ChatRoomModel>> getConversations(String currentUserId);

  Stream<List<ChatRoomModel>> streamConversations(String userId);

  Future<List<MessageModel>> fetchOlderMessages({
    required String roomId,
    required DateTime before,
    int limit = 30,
  });

  Future<void> updateReadStatus({
    required String roomId,
    required String currentUserId,
  });

  Future<List<UserProfileEntity>> getUsers(String excludeUid);

  Future<void> setTyping({
    required String roomId,
    required String uid,
    required bool isTyping,
  });

  Stream<bool> streamPartnerTyping({
    required String roomId,
    required String partnerUid,
  });

  Future<void> updatePresence({
    required String uid,
    required bool isOnline,
  });

  Stream<Map<String, dynamic>?> streamUserPresence(String uid);

  Future<void> togglePin({
    required String roomId,
    required String uid,
    required bool pin,
  });

  Future<void> toggleMute({
    required String roomId,
    required String uid,
    required bool mute,
  });

  Future<void> saveFcmToken({
    required String uid,
    required String token,
  });

  // Keeps the messaging feature's own `users/{uid}` doc (read by getUsers()
  // for "start new chat", and copied into a room's participantNames the
  // first time a chat is opened) in sync with the real, REST-backed
  // profile — that's the actual source of truth for a user's display name,
  // and this collection has no other writer for it in the normal
  // signup/login flow, which is why an un-synced user's name previously
  // always fell back to the literal "Unknown".
  Future<void> syncUserProfile({
    required String uid,
    required String name,
    String? avatarUrl,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRemoteDataSourceImpl(this._firestore, this._storage);

  static String buildRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chat_rooms');

  CollectionReference<Map<String, dynamic>> _messages(String roomId) =>
      _rooms.doc(roomId).collection('messages');

  @override
  Future<ChatRoomModel> createOrGetRoom({
    required String currentUserId,
    required String partnerId,
    required String currentUserName,
    required String partnerName,
    String? currentUserAvatarUrl,
    String? partnerAvatarUrl,
  }) async {
    final roomId = buildRoomId(currentUserId, partnerId);
    final ref = _rooms.doc(roomId);
    final snap = await ref.get();

    if (snap.exists && snap.data() != null) {
      final data = Map<String, dynamic>.from(snap.data()!);
      data['roomId'] = snap.id;

      // Self-heal: refresh OUR OWN name/avatar in this room's
      // participantNames/participantAvatars every time we open or use it,
      // not just at room creation. Only the caller's own entry is ever
      // touched here — never the partner's — because `partnerName`/
      // `partnerAvatarUrl` are whatever the caller happens to have cached
      // and could themselves be stale; blindly overwriting the partner's
      // entry with that could undo a self-heal the partner already did on
      // their own side the next time they opened this same room.
      final storedNames = Map<String, dynamic>.from(
          (data['participantNames'] as Map?) ?? const {});
      final storedAvatars = Map<String, dynamic>.from(
          (data['participantAvatars'] as Map?) ?? const {});
      if (storedNames[currentUserId] != currentUserName ||
          storedAvatars[currentUserId] != currentUserAvatarUrl) {
        storedNames[currentUserId] = currentUserName;
        storedAvatars[currentUserId] = currentUserAvatarUrl;
        await ref.update({
          'participantNames': storedNames,
          'participantAvatars': storedAvatars,
        });
        data['participantNames'] = storedNames;
        data['participantAvatars'] = storedAvatars;
      }

      return ChatRoomModel.fromJson(data);
    }

    final now = Timestamp.now();
    final roomData = <String, dynamic>{
      'roomId': roomId,
      'participants': [currentUserId, partnerId],
      'lastMessage': '',
      'lastMessageTime': null,
      'createdAt': now,
      'isBlocked': false,
      'blockedBy': null,
      'participantNames': {
        currentUserId: currentUserName,
        partnerId: partnerName,
      },
      'participantAvatars': {
        currentUserId: currentUserAvatarUrl,
        partnerId: partnerAvatarUrl,
      },
      'unreadCounts': {
        currentUserId: 0,
        partnerId: 0,
      },
      'pinnedBy': [],
      'mutedBy': [],
    };

    await ref.set(roomData);
    return ChatRoomModel.fromJson(roomData);
  }

  @override
  Future<ChatRoomModel?> getRoom(String roomId) async {
    final snap = await _rooms.doc(roomId).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = Map<String, dynamic>.from(snap.data()!);
    data['roomId'] = snap.id;
    return ChatRoomModel.fromJson(data);
  }

  @override
  Future<MessageModel> sendMessage({
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
    final msgRef = _messages(roomId).doc();
    final now = Timestamp.now();

    final msgData = <String, dynamic>{
      'messageId': msgRef.id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': content,
      'type': type,
      'isRead': false,
      'createdAt': now,
    };

    if (attachmentUrl != null) msgData['attachmentUrl'] = attachmentUrl;
    if (fileName != null) msgData['fileName'] = fileName;
    if (fileSize != null) msgData['fileSize'] = fileSize;
    if (mimeType != null) msgData['mimeType'] = mimeType;

    final batch = _firestore.batch();
    batch.set(msgRef, msgData);
    batch.update(_rooms.doc(roomId), {
      'lastMessage': content,
      'lastMessageTime': now,
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });
    await batch.commit();

    return MessageModel.fromJson(msgData);
  }

  @override
  Stream<UploadProgress> uploadFile({
    required String roomId,
    required File file,
    required String fileName,
    String? mimeType,
  }) async* {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final storagePath = 'chat_attachments/$roomId/${timestamp}_$safeName';
    final ref = _storage.ref(storagePath);

    final metadata = mimeType != null
        ? SettableMetadata(contentType: mimeType)
        : null;
    final task = metadata != null
        ? ref.putFile(file, metadata)
        : ref.putFile(file);

    await for (final snapshot in task.snapshotEvents) {
      if (snapshot.state == TaskState.running) {
        final total = snapshot.totalBytes;
        if (total > 0) {
          yield UploadProgress(
            progress: snapshot.bytesTransferred / total,
          );
        }
      } else if (snapshot.state == TaskState.error) {
        throw Exception('Upload failed');
      }
    }

    final downloadUrl = await ref.getDownloadURL();
    yield UploadProgress(progress: 1.0, downloadUrl: downloadUrl);
  }

  @override
  Stream<List<MessageModel>> streamMessages(String roomId) {
    return _messages(roomId)
        .orderBy('createdAt', descending: false)
        .limitToLast(30)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['messageId'] = doc.id;
              return MessageModel.fromJson(data);
            }).toList());
  }

  @override
  Stream<List<MessageModel>> streamMessagesWithLimit(
      String roomId, int limit) {
    return _messages(roomId)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['messageId'] = doc.id;
              return MessageModel.fromJson(data);
            }).toList());
  }

  @override
  Future<List<MessageModel>> fetchOlderMessages({
    required String roomId,
    required DateTime before,
    int limit = 30,
  }) async {
    final beforeTs = Timestamp.fromDate(before);
    final snap = await _messages(roomId)
        .orderBy('createdAt', descending: false)
        .where('createdAt', isLessThan: beforeTs)
        .limitToLast(limit)
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['messageId'] = doc.id;
      return MessageModel.fromJson(data);
    }).toList();
  }

  @override
  Future<List<ChatRoomModel>> getConversations(String currentUserId) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _rooms
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .get();
    } catch (_) {
      snap = await _rooms
          .where('participants', arrayContains: currentUserId)
          .get();
    }

    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['roomId'] = doc.id;
      return ChatRoomModel.fromJson(data);
    }).toList();
  }

  @override
  Stream<List<ChatRoomModel>> streamConversations(String userId) {
    return _rooms
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final rooms = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['roomId'] = doc.id;
        return ChatRoomModel.fromJson(data);
      }).toList();
      rooms.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt;
        final bTime = b.lastMessageTime ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      return rooms;
    });
  }

  @override
  Future<void> updateReadStatus({
    required String roomId,
    required String currentUserId,
  }) async {
    final unreadSnap = await _messages(roomId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadSnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadSnap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    batch.update(_rooms.doc(roomId), {
      'unreadCounts.$currentUserId': 0,
    });
    await batch.commit();
  }

  @override
  Future<List<UserProfileEntity>> getUsers(String excludeUid) async {
    final snap = await _firestore.collection('users').get();
    return snap.docs
        .map((d) => UserProfileEntity.fromJson(d.data()))
        .where((u) => u.uid.isNotEmpty && u.uid != excludeUid)
        .toList();
  }

  @override
  Future<void> setTyping({
    required String roomId,
    required String uid,
    required bool isTyping,
  }) async {
    final ref = _rooms.doc(roomId);
    if (isTyping) {
      await ref.update({'typing.$uid': FieldValue.serverTimestamp()});
    } else {
      await ref.update({'typing.$uid': FieldValue.delete()});
    }
  }

  @override
  Stream<bool> streamPartnerTyping({
    required String roomId,
    required String partnerUid,
  }) {
    return _rooms.doc(roomId).snapshots().map((snap) {
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;
      final typing = data['typing'] as Map<String, dynamic>?;
      if (typing == null) return false;
      final partnerTs = typing[partnerUid];
      if (partnerTs == null) return false;
      if (partnerTs is! Timestamp) return false;
      return DateTime.now().difference(partnerTs.toDate()).inSeconds < 6;
    });
  }

  @override
  Future<void> updatePresence({
    required String uid,
    required bool isOnline,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Stream<Map<String, dynamic>?> streamUserPresence(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  @override
  Future<void> togglePin({
    required String roomId,
    required String uid,
    required bool pin,
  }) async {
    await _rooms.doc(roomId).update({
      'pinnedBy': pin
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> toggleMute({
    required String roomId,
    required String uid,
    required bool mute,
  }) async {
    await _rooms.doc(roomId).update({
      'mutedBy': mute
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> syncUserProfile({
    required String uid,
    required String name,
    String? avatarUrl,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      SetOptions(merge: true),
    );
  }
}
