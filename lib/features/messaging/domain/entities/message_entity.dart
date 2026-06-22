import 'package:equatable/equatable.dart';

enum MessageType { text, meetingInvite, image, document }
enum MessageStatus { sending, sent, delivered, read, failed }
enum UploadStatus { uploading, uploaded, failed }

// ── Attachment ────────────────────────────────────────────────────────────────

class AttachmentEntity extends Equatable {
  final String url;
  final String? localPath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final UploadStatus uploadStatus;

  const AttachmentEntity({
    required this.url,
    this.localPath,
    this.fileName,
    this.fileSize,
    this.mimeType,
    required this.uploadStatus,
  });

  bool get isImage {
    if (mimeType != null) return mimeType!.startsWith('image/');
    if (fileName != null) {
      final ext = fileName!.split('.').last.toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'].contains(ext);
    }
    return false;
  }

  bool get isDocument => !isImage;

  String get displayName {
    if (fileName != null && fileName!.isNotEmpty) return fileName!;
    if (url.isNotEmpty) return url.split('/').last.split('?').first;
    return 'Attachment';
  }

  String get formattedSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get extensionLabel {
    if (fileName == null) return 'FILE';
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  AttachmentEntity copyWith({
    String? url,
    String? localPath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    UploadStatus? uploadStatus,
  }) =>
      AttachmentEntity(
        url: url ?? this.url,
        localPath: localPath ?? this.localPath,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
        uploadStatus: uploadStatus ?? this.uploadStatus,
      );

  @override
  List<Object?> get props =>
      [url, localPath, fileName, fileSize, mimeType, uploadStatus];
}

// ── Upload progress (used in repository stream) ───────────────────────────────

class UploadProgress extends Equatable {
  final double progress;
  final String? downloadUrl;

  const UploadProgress({required this.progress, this.downloadUrl});

  bool get isComplete => downloadUrl != null;

  @override
  List<Object?> get props => [progress, downloadUrl];
}

// ── Conversation ──────────────────────────────────────────────────────────────

class ConversationEntity extends Equatable {
  final String id;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String partnerVerificationLevel;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isMuted;

  const ConversationEntity({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.partnerVerificationLevel,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
    this.isPinned = false,
    this.isMuted = false,
  });

  String get partnerInitials {
    final parts = partnerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props =>
      [id, partnerId, partnerName, lastMessage, unreadCount, updatedAt, isPinned, isMuted];
}

// ── Message ───────────────────────────────────────────────────────────────────

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final MeetingInviteEntity? meetingInvite;
  final AttachmentEntity? attachment;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.meetingInvite,
    this.attachment,
  });

  bool get isMine => false;

  bool get isAttachment =>
      type == MessageType.image || type == MessageType.document;

  MessageEntity copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageStatus? status,
    AttachmentEntity? attachment,
    bool clearAttachment = false,
  }) =>
      MessageEntity(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        content: content ?? this.content,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt,
        meetingInvite: meetingInvite,
        attachment: clearAttachment ? null : (attachment ?? this.attachment),
      );

  @override
  List<Object?> get props =>
      [id, conversationId, senderId, content, type, status, createdAt, attachment];
}

// ── Meeting invite ────────────────────────────────────────────────────────────

class MeetingInviteEntity extends Equatable {
  final String meetingId;
  final String purpose;
  final DateTime scheduledAt;
  final String status;

  const MeetingInviteEntity({
    required this.meetingId,
    required this.purpose,
    required this.scheduledAt,
    required this.status,
  });

  @override
  List<Object?> get props => [meetingId, purpose, scheduledAt, status];
}
