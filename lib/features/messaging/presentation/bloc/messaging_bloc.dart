import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../../domain/use_cases/create_or_get_room_use_case.dart';
import '../../domain/use_cases/get_users_use_case.dart';
import '../../domain/use_cases/mark_message_read_use_case.dart';
import '../../domain/use_cases/send_message_use_case.dart';
import '../../domain/use_cases/upload_attachment_use_case.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override
  List<Object?> get props => [];
}

class FetchConversations extends MessagingEvent {
  const FetchConversations();
}

class OpenOrCreateChatRoom extends MessagingEvent {
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String currentUserName;

  const OpenOrCreateChatRoom({
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    this.currentUserName = 'Me',
  });

  @override
  List<Object?> get props =>
      [partnerId, partnerName, partnerAvatarUrl, currentUserName];
}

class SendChatMessage extends MessagingEvent {
  final String roomId;
  final String receiverId;
  final String content;

  const SendChatMessage({
    required this.roomId,
    required this.receiverId,
    required this.content,
  });

  @override
  List<Object?> get props => [roomId, receiverId, content];
}

class SendAttachmentMessage extends MessagingEvent {
  final String roomId;
  final String receiverId;
  final String filePath;
  final MessageType attachmentType;
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final String? caption;
  final String? retryTempId;

  const SendAttachmentMessage({
    required this.roomId,
    required this.receiverId,
    required this.filePath,
    required this.attachmentType,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.caption,
    this.retryTempId,
  });

  @override
  List<Object?> get props => [
        roomId,
        receiverId,
        filePath,
        attachmentType,
        fileName,
        fileSize,
        mimeType,
        retryTempId
      ];
}

class MarkChatRead extends MessagingEvent {
  final String roomId;
  const MarkChatRead(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class FetchUsers extends MessagingEvent {
  const FetchUsers();
}

class SetTyping extends MessagingEvent {
  final bool isTyping;
  const SetTyping(this.isTyping);
  @override
  List<Object?> get props => [isTyping];
}

class PinConversation extends MessagingEvent {
  final String roomId;
  final bool pin;
  const PinConversation({required this.roomId, required this.pin});
  @override
  List<Object?> get props => [roomId, pin];
}

class MuteConversation extends MessagingEvent {
  final String roomId;
  final bool mute;
  const MuteConversation({required this.roomId, required this.mute});
  @override
  List<Object?> get props => [roomId, mute];
}

class LoadOlderMessages extends MessagingEvent {
  const LoadOlderMessages();
}

// Internal events
class _ConversationsUpdated extends MessagingEvent {
  final List<ConversationEntity> conversations;
  const _ConversationsUpdated(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class _ConversationsError extends MessagingEvent {
  final String message;
  const _ConversationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class _StreamBatchReceived extends MessagingEvent {
  final List<MessageEntity> messages;
  const _StreamBatchReceived(this.messages);
  @override
  List<Object?> get props => [messages];
}

class _TypingChanged extends MessagingEvent {
  final bool isTyping;
  const _TypingChanged(this.isTyping);
  @override
  List<Object?> get props => [isTyping];
}

class _PresenceChanged extends MessagingEvent {
  final bool isOnline;
  final DateTime? lastSeen;
  const _PresenceChanged({required this.isOnline, this.lastSeen});
  @override
  List<Object?> get props => [isOnline, lastSeen];
}

class _AttachmentProgressUpdated extends MessagingEvent {
  final String tempId;
  final double progress;
  const _AttachmentProgressUpdated(
      {required this.tempId, required this.progress});
  @override
  List<Object?> get props => [tempId, progress];
}

class _AttachmentUploadFailed extends MessagingEvent {
  final String tempId;
  const _AttachmentUploadFailed(this.tempId);
  @override
  List<Object?> get props => [tempId];
}

class _AttachmentUploadCompleted extends MessagingEvent {
  final String tempId;
  const _AttachmentUploadCompleted(this.tempId);
  @override
  List<Object?> get props => [tempId];
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class MessagingState extends Equatable {
  const MessagingState();
  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

class MessagingLoading extends MessagingState {
  const MessagingLoading();
}

class ConversationsState extends MessagingState {
  final List<ConversationEntity> conversations;
  const ConversationsState(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class ChatState extends MessagingState {
  final String roomId;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String currentUserId;
  final List<MessageEntity> messages;
  final bool isSending;
  final bool isPartnerTyping;
  final bool isPartnerOnline;
  final DateTime? partnerLastSeen;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final bool isInitializing;
  // tempId → upload progress (0.0–1.0)
  final Map<String, double> uploadProgressMap;

  const ChatState({
    required this.roomId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.currentUserId,
    required this.messages,
    this.isSending = false,
    this.isPartnerTyping = false,
    this.isPartnerOnline = false,
    this.partnerLastSeen,
    this.hasMoreMessages = false,
    this.isLoadingMore = false,
    this.isInitializing = false,
    this.uploadProgressMap = const {},
  });

  ChatState copyWith({
    List<MessageEntity>? messages,
    bool? isSending,
    bool? isPartnerTyping,
    bool? isPartnerOnline,
    DateTime? partnerLastSeen,
    bool clearLastSeen = false,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    bool? isInitializing,
    Map<String, double>? uploadProgressMap,
  }) =>
      ChatState(
        roomId: roomId,
        partnerId: partnerId,
        partnerName: partnerName,
        partnerAvatarUrl: partnerAvatarUrl,
        currentUserId: currentUserId,
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
        isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
        partnerLastSeen:
            clearLastSeen ? null : (partnerLastSeen ?? this.partnerLastSeen),
        hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isInitializing: isInitializing ?? this.isInitializing,
        uploadProgressMap: uploadProgressMap ?? this.uploadProgressMap,
      );

  @override
  List<Object?> get props => [
        roomId,
        partnerId,
        partnerName,
        currentUserId,
        messages,
        isSending,
        isPartnerTyping,
        isPartnerOnline,
        partnerLastSeen,
        hasMoreMessages,
        isLoadingMore,
        isInitializing,
        uploadProgressMap,
      ];
}

class UsersLoaded extends MessagingState {
  final List<UserProfileEntity> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class MessagingError extends MessagingState {
  final String message;
  const MessagingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final CreateOrGetRoomUseCase _createOrGetRoom;
  final GetUsersUseCase _getUsers;
  final SendMessageUseCase _sendMessage;
  final MarkMessageReadUseCase _markRead;
  final UploadAttachmentUseCase _uploadAttachment;
  final SecureStorageService _session;
  final MessagingRepository _repository;

  StreamSubscription<List<ConversationEntity>>? _convSub;
  StreamSubscription<List<MessageEntity>>? _msgSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<Map<String, dynamic>?>? _presenceSub;
  // Keyed by tempId to support concurrent uploads
  final Map<String, StreamSubscription<UploadProgress>> _uploadSubs = {};

  String? _typingRoomId;
  int _messageStreamLimit = 30;

  MessagingBloc({
    required CreateOrGetRoomUseCase createOrGetRoom,
    required GetUsersUseCase getUsers,
    required SendMessageUseCase sendMessage,
    required MarkMessageReadUseCase markRead,
    required UploadAttachmentUseCase uploadAttachment,
    required SecureStorageService session,
    required MessagingRepository repository,
  })  : _createOrGetRoom = createOrGetRoom,
        _getUsers = getUsers,
        _sendMessage = sendMessage,
        _markRead = markRead,
        _uploadAttachment = uploadAttachment,
        _session = session,
        _repository = repository,
        super(const MessagingInitial()) {
    on<FetchConversations>(_onFetchConversations);
    on<FetchUsers>(_onFetchUsers);
    on<OpenOrCreateChatRoom>(_onOpenOrCreate);
    on<SendChatMessage>(_onSendMessage);
    on<SendAttachmentMessage>(_onSendAttachmentMessage);
    on<MarkChatRead>(_onMarkRead);
    on<SetTyping>(_onSetTyping);
    on<PinConversation>(_onPinConversation);
    on<MuteConversation>(_onMuteConversation);
    on<LoadOlderMessages>(_onLoadOlderMessages);
    on<_ConversationsUpdated>(_onConversationsUpdated);
    on<_ConversationsError>(_onConversationsError);
    on<_StreamBatchReceived>(_onStreamBatch);
    on<_TypingChanged>(_onTypingChanged);
    on<_PresenceChanged>(_onPresenceChanged);
    on<_AttachmentProgressUpdated>(_onAttachmentProgress);
    on<_AttachmentUploadFailed>(_onAttachmentFailed);
    on<_AttachmentUploadCompleted>(_onAttachmentCompleted);
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onFetchConversations(
    FetchConversations _,
    Emitter<MessagingState> emit,
  ) async {
    await _convSub?.cancel();
    _convSub = null;

    emit(const MessagingLoading());

    final uid = await _session.getUserId();
    if (uid == null) {
      emit(const MessagingError('Not signed in'));
      return;
    }

    _convSub = _repository.conversationsStream(uid).listen(
          (list) => add(_ConversationsUpdated(list)),
          onError: (_) =>
              add(const _ConversationsError('Failed to load conversations')),
        );
  }

  void _onConversationsUpdated(
    _ConversationsUpdated event,
    Emitter<MessagingState> emit,
  ) {
    emit(ConversationsState(event.conversations));
  }

  void _onConversationsError(
    _ConversationsError event,
    Emitter<MessagingState> emit,
  ) {
    emit(MessagingError(event.message));
  }

  Future<void> _onFetchUsers(
    FetchUsers _,
    Emitter<MessagingState> emit,
  ) async {
    // Skip the full-screen loading state on a pull-to-refresh — only the
    // very first load should blank the screen while it fetches.
    if (state is! UsersLoaded) emit(const MessagingLoading());
    final uid = await _session.getUserId();
    if (uid == null) {
      emit(const MessagingError('Not signed in'));
      return;
    }
    final result = await _getUsers(uid);
    result.fold(
      (f) => emit(MessagingError(f.message)),
      (users) => emit(UsersLoaded(users)),
    );
  }

  Future<void> _onOpenOrCreate(
    OpenOrCreateChatRoom event,
    Emitter<MessagingState> emit,
  ) async {
    final uid = await _session.getUserId();
    if (uid == null) {
      emit(const MessagingError('Not signed in'));
      return;
    }

    final ids = [uid, event.partnerId]..sort();
    final roomId = '${ids[0]}_${ids[1]}';

    _messageStreamLimit = 30;

    emit(ChatState(
      roomId: roomId,
      partnerId: event.partnerId,
      partnerName: event.partnerName,
      partnerAvatarUrl: event.partnerAvatarUrl,
      currentUserId: uid,
      messages: const [],
      hasMoreMessages: false,
      isInitializing: true,
    ));

    _typingRoomId = roomId;
    _subscribeToMessages(roomId);
    _subscribeToTyping(roomId, event.partnerId);
    _subscribeToPresence(event.partnerId);
    _repository.updatePresence(true).ignore();

    _createOrGetRoom(
      currentUserId: uid,
      partnerId: event.partnerId,
      currentUserName: event.currentUserName,
      partnerName: event.partnerName,
      partnerAvatarUrl: event.partnerAvatarUrl,
    ).ignore();
  }

  Future<void> _onSendMessage(
    SendChatMessage event,
    Emitter<MessagingState> emit,
  ) async {
    if (state is! ChatState) return;
    final current = state as ChatState;

    final uid = await _session.getUserId();
    if (uid == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = MessageEntity(
      id: tempId,
      conversationId: event.roomId,
      senderId: uid,
      content: event.content,
      type: MessageType.text,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    emit(current.copyWith(
      messages: [...current.messages, optimistic],
      isSending: false,
    ));

    final result = await _sendMessage(
      roomId: event.roomId,
      senderId: uid,
      receiverId: event.receiverId,
      content: event.content,
    );

    result.fold(
      (f) {
        if (state is ChatState) {
          final s = state as ChatState;
          emit(s.copyWith(
            messages: s.messages.where((m) => m.id != tempId).toList(),
          ));
        }
      },
      (_) {},
    );
  }

  Future<void> _onSendAttachmentMessage(
    SendAttachmentMessage event,
    Emitter<MessagingState> emit,
  ) async {
    if (state is! ChatState) return;
    final current = state as ChatState;

    final uid = await _session.getUserId();
    if (uid == null) return;

    // Validate file size
    final file = File(event.filePath);
    if (!file.existsSync()) return;
    final maxSize = event.attachmentType == MessageType.image
        ? AppConstants.maxImageSizeBytes
        : AppConstants.maxDocumentSizeBytes;
    if (event.fileSize > maxSize) return;

    final tempId =
        event.retryTempId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final displayContent = event.attachmentType == MessageType.image
        ? (event.caption?.isNotEmpty == true ? event.caption! : '📷 Photo')
        : '📄 ${event.fileName}';

    final optimistic = MessageEntity(
      id: tempId,
      conversationId: event.roomId,
      senderId: uid,
      content: displayContent,
      type: event.attachmentType,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      attachment: AttachmentEntity(
        url: '',
        localPath: event.filePath,
        fileName: event.fileName,
        fileSize: event.fileSize,
        mimeType: event.mimeType,
        uploadStatus: UploadStatus.uploading,
      ),
    );

    // Add new message or replace existing (retry)
    final List<MessageEntity> updatedMessages;
    if (event.retryTempId != null) {
      updatedMessages =
          current.messages.map((m) => m.id == tempId ? optimistic : m).toList();
    } else {
      updatedMessages = [...current.messages, optimistic];
    }

    final updatedProgress = Map<String, double>.from(current.uploadProgressMap)
      ..[tempId] = 0.0;

    emit(current.copyWith(
      messages: updatedMessages,
      uploadProgressMap: updatedProgress,
    ));

    // Cancel any existing subscription for this tempId (retry case)
    await _uploadSubs[tempId]?.cancel();

    String? downloadUrl;

    _uploadSubs[tempId] = _uploadAttachment(
      roomId: event.roomId,
      file: file,
      fileName: event.fileName,
      mimeType: event.mimeType,
    ).listen(
      (progress) {
        if (progress.isComplete) {
          downloadUrl = progress.downloadUrl;
          add(_AttachmentUploadCompleted(tempId));
        } else {
          add(_AttachmentProgressUpdated(
              tempId: tempId, progress: progress.progress));
        }
      },
      onError: (_) => add(_AttachmentUploadFailed(tempId)),
      onDone: () {
        // If stream closes without isComplete being set, treat as failure
        if (downloadUrl == null && !isClosed) {
          add(_AttachmentUploadFailed(tempId));
        }
      },
    );

    // Store downloadUrl accessible to _onAttachmentCompleted via closure
    // We use a separate map to hand the URL over since events are stateless
    _pendingDownloadUrls[tempId] = () => downloadUrl;

    // Store event data for after-upload send
    _pendingAttachmentEvents[tempId] = event;
  }

  // Closures that let _onAttachmentCompleted retrieve the URL and event
  final Map<String, String? Function()> _pendingDownloadUrls = {};
  final Map<String, SendAttachmentMessage> _pendingAttachmentEvents = {};

  void _onAttachmentProgress(
    _AttachmentProgressUpdated event,
    Emitter<MessagingState> emit,
  ) {
    if (state is! ChatState) return;
    final current = state as ChatState;
    final updated = Map<String, double>.from(current.uploadProgressMap)
      ..[event.tempId] = event.progress;
    emit(current.copyWith(uploadProgressMap: updated));
  }

  Future<void> _onAttachmentFailed(
    _AttachmentUploadFailed event,
    Emitter<MessagingState> emit,
  ) async {
    await _uploadSubs.remove(event.tempId)?.cancel();
    _pendingDownloadUrls.remove(event.tempId);
    _pendingAttachmentEvents.remove(event.tempId);

    if (state is! ChatState) return;
    final current = state as ChatState;

    // Mark the optimistic message as failed and remove its progress entry
    final updatedMessages = current.messages.map((m) {
      if (m.id != event.tempId) return m;
      return m.copyWith(
        status: MessageStatus.failed,
        attachment: m.attachment?.copyWith(uploadStatus: UploadStatus.failed),
      );
    }).toList();

    final updatedProgress = Map<String, double>.from(current.uploadProgressMap)
      ..remove(event.tempId);

    emit(current.copyWith(
      messages: updatedMessages,
      uploadProgressMap: updatedProgress,
    ));
  }

  Future<void> _onAttachmentCompleted(
    _AttachmentUploadCompleted event,
    Emitter<MessagingState> emit,
  ) async {
    await _uploadSubs.remove(event.tempId)?.cancel();

    final downloadUrl = _pendingDownloadUrls.remove(event.tempId)?.call();
    final pendingEvent = _pendingAttachmentEvents.remove(event.tempId);

    if (downloadUrl == null || pendingEvent == null) return;
    if (state is! ChatState) return;
    final current = state as ChatState;

    final uid = current.currentUserId;
    final typeStr =
        pendingEvent.attachmentType == MessageType.image ? 'image' : 'document';
    final displayContent = pendingEvent.attachmentType == MessageType.image
        ? (pendingEvent.caption?.isNotEmpty == true
            ? pendingEvent.caption!
            : '📷 Photo')
        : '📄 ${pendingEvent.fileName}';

    // Send the confirmed message to Firestore
    await _sendMessage(
      roomId: pendingEvent.roomId,
      senderId: uid,
      receiverId: pendingEvent.receiverId,
      content: displayContent,
      type: typeStr,
      attachmentUrl: downloadUrl,
      fileName: pendingEvent.fileName,
      fileSize: pendingEvent.fileSize,
      mimeType: pendingEvent.mimeType,
    );

    // Remove progress entry; Firestore stream will replace the optimistic message
    if (state is ChatState) {
      final s = state as ChatState;
      final updatedProgress = Map<String, double>.from(s.uploadProgressMap)
        ..remove(event.tempId);
      emit(s.copyWith(uploadProgressMap: updatedProgress));
    }
  }

  Future<void> _onMarkRead(
    MarkChatRead event,
    Emitter<MessagingState> emit,
  ) async {
    final uid = await _session.getUserId();
    if (uid == null) return;
    await _markRead(roomId: event.roomId, currentUserId: uid);
  }

  Future<void> _onSetTyping(
    SetTyping event,
    Emitter<MessagingState> emit,
  ) async {
    if (state is! ChatState) return;
    final roomId = (state as ChatState).roomId;
    await _repository.setTyping(roomId: roomId, isTyping: event.isTyping);
  }

  Future<void> _onPinConversation(
    PinConversation event,
    Emitter<MessagingState> emit,
  ) async {
    await _repository.togglePin(roomId: event.roomId, pin: event.pin);
  }

  Future<void> _onMuteConversation(
    MuteConversation event,
    Emitter<MessagingState> emit,
  ) async {
    await _repository.toggleMute(roomId: event.roomId, mute: event.mute);
  }

  Future<void> _onLoadOlderMessages(
    LoadOlderMessages _,
    Emitter<MessagingState> emit,
  ) async {
    if (state is! ChatState) return;
    final current = state as ChatState;
    if (!current.hasMoreMessages || current.isLoadingMore) return;
    if (current.messages.isEmpty) return;

    emit(current.copyWith(isLoadingMore: true));

    final oldestTimestamp = current.messages.first.createdAt;
    final result = await _repository.fetchOlderMessages(
      roomId: current.roomId,
      before: oldestTimestamp,
    );

    result.fold(
      (f) {
        if (state is ChatState) {
          emit((state as ChatState).copyWith(isLoadingMore: false));
        }
      },
      (older) {
        if (state is! ChatState) return;
        final s = state as ChatState;
        final merged = [...older, ...s.messages];
        merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        emit(s.copyWith(
          messages: merged,
          isLoadingMore: false,
          hasMoreMessages: older.length >= 30,
        ));

        if (older.isNotEmpty) {
          _messageStreamLimit = merged.length + 10;
          _subscribeToMessages(s.roomId);
        }
      },
    );
  }

  void _onStreamBatch(
    _StreamBatchReceived event,
    Emitter<MessagingState> emit,
  ) {
    if (state is! ChatState) return;
    final current = state as ChatState;

    final streamKeys =
        event.messages.map((m) => '${m.senderId}:${m.content}').toSet();

    // Keep pending temps that haven't arrived from Firestore yet
    final pendingTemps = current.messages
        .where((m) =>
            m.id.startsWith('temp_') &&
            !streamKeys.contains('${m.senderId}:${m.content}'))
        .toList();

    // Preserve pagination-loaded messages older than the stream window
    final olderLoaded = event.messages.isEmpty
        ? <MessageEntity>[]
        : current.messages
            .where((m) =>
                !m.id.startsWith('temp_') &&
                m.createdAt.isBefore(event.messages.first.createdAt))
            .toList();

    final merged = [...olderLoaded, ...event.messages, ...pendingTemps];
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final hasMore = event.messages.length >= _messageStreamLimit ||
        (current.hasMoreMessages && olderLoaded.isNotEmpty);

    emit(current.copyWith(
      messages: merged,
      hasMoreMessages: hasMore,
      isInitializing: false,
    ));
  }

  void _onTypingChanged(
    _TypingChanged event,
    Emitter<MessagingState> emit,
  ) {
    if (state is ChatState) {
      emit((state as ChatState).copyWith(isPartnerTyping: event.isTyping));
    }
  }

  void _onPresenceChanged(
    _PresenceChanged event,
    Emitter<MessagingState> emit,
  ) {
    if (state is ChatState) {
      emit((state as ChatState).copyWith(
        isPartnerOnline: event.isOnline,
        partnerLastSeen: event.lastSeen,
      ));
    }
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  void _subscribeToMessages(String roomId) {
    _msgSub?.cancel();
    _msgSub =
        _repository.messageStreamWithLimit(roomId, _messageStreamLimit).listen(
              (msgs) => add(_StreamBatchReceived(msgs)),
              onError: (_) {},
            );
  }

  void _subscribeToTyping(String roomId, String partnerUid) {
    _typingSub?.cancel();
    bool lastTyping = false;
    _typingSub = _repository.partnerTypingStream(roomId, partnerUid).listen(
      (isTyping) {
        if (isTyping != lastTyping) {
          lastTyping = isTyping;
          add(_TypingChanged(isTyping));
        }
      },
      onError: (_) {},
    );
  }

  void _subscribeToPresence(String partnerUid) {
    _presenceSub?.cancel();
    _presenceSub = _repository.userPresenceStream(partnerUid).listen(
      (data) {
        if (data == null) return;
        final isOnline = data['isOnline'] as bool? ?? false;
        DateTime? lastSeen;
        final rawLastSeen = data['lastSeen'];
        if (rawLastSeen is DateTime) {
          lastSeen = rawLastSeen;
        } else {
          try {
            lastSeen = (rawLastSeen as dynamic).toDate() as DateTime?;
          } catch (_) {}
        }
        add(_PresenceChanged(isOnline: isOnline, lastSeen: lastSeen));
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> close() async {
    if (_typingRoomId != null) {
      _repository.setTyping(roomId: _typingRoomId!, isTyping: false).ignore();
    }
    await _convSub?.cancel();
    await _msgSub?.cancel();
    await _typingSub?.cancel();
    await _presenceSub?.cancel();
    for (final sub in _uploadSubs.values) {
      await sub.cancel();
    }
    _uploadSubs.clear();
    _pendingDownloadUrls.clear();
    _pendingAttachmentEvents.clear();
    return super.close();
  }
}
