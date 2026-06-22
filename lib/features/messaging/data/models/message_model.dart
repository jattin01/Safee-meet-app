import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends Equatable {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  // Attachment fields — null for plain text messages (backward compatible)
  final String? attachmentUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.attachmentUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    final raw = json['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return MessageModel(
      messageId: json['messageId'] as String? ?? json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: createdAt,
      attachmentUrl: json['attachmentUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (attachmentUrl != null) map['attachmentUrl'] = attachmentUrl;
    if (fileName != null) map['fileName'] = fileName;
    if (fileSize != null) map['fileSize'] = fileSize;
    if (mimeType != null) map['mimeType'] = mimeType;
    return map;
  }

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? attachmentUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
  }) =>
      MessageModel(
        messageId: messageId ?? this.messageId,
        senderId: senderId ?? this.senderId,
        receiverId: receiverId ?? this.receiverId,
        message: message ?? this.message,
        type: type ?? this.type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
      );

  MessageEntity toEntity(String roomId) {
    final msgType = _parseType(type);
    AttachmentEntity? attachment;
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty) {
      attachment = AttachmentEntity(
        url: attachmentUrl!,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        uploadStatus: UploadStatus.uploaded,
      );
    }

    return MessageEntity(
      id: messageId,
      conversationId: roomId,
      senderId: senderId,
      content: message,
      type: msgType,
      status: isRead ? MessageStatus.read : MessageStatus.sent,
      createdAt: createdAt,
      attachment: attachment,
    );
  }

  static MessageType _parseType(String raw) {
    switch (raw) {
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'meetingInvite':
        return MessageType.meetingInvite;
      default:
        return MessageType.text;
    }
  }

  @override
  List<Object?> get props => [
        messageId,
        senderId,
        receiverId,
        message,
        type,
        isRead,
        createdAt,
        attachmentUrl,
        fileName,
        fileSize,
        mimeType,
      ];
}
