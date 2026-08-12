import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/app_snackbar.dart';
import '../../../../core/shared/widgets/skeleton_item.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/messaging_bloc.dart';
import '../widgets/attachment_picker_sheet.dart';
import 'image_preview_page.dart';

class ChatPage extends StatelessWidget {
  final String conversationId;
  final ConversationEntity? conversation;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<MessagingBloc>();
        if (conversation != null) {
          bloc.add(OpenOrCreateChatRoom(
            partnerId: conversation!.partnerId,
            partnerName: conversation!.partnerName,
            partnerAvatarUrl: conversation!.partnerAvatarUrl,
          ));
        }
        return bloc;
      },
      child: _ChatView(
        initialPartnerName: conversation?.partnerName,
        initialAvatarUrl: conversation?.partnerAvatarUrl,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String? initialPartnerName;
  final String? initialAvatarUrl;

  const _ChatView({this.initialPartnerName, this.initialAvatarUrl});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _typingTimer;
  bool _loadMoreDebounce = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _loadMoreDebounce) return;
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      final bloc = context.read<MessagingBloc>();
      final s = bloc.state;
      if (s is ChatState && s.hasMoreMessages && !s.isLoadingMore) {
        _loadMoreDebounce = true;
        bloc.add(const LoadOlderMessages());
        Future.delayed(const Duration(seconds: 2), () {
          _loadMoreDebounce = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.pixels > 0) {
        _scrollCtrl.jumpTo(0);
      }
    });
  }

  void _onInputChanged(BuildContext context) {
    context.read<MessagingBloc>().add(const SetTyping(true));
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<MessagingBloc>().add(const SetTyping(false));
      }
    });
  }

  void _send(BuildContext context, ChatState state) {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;
    _textCtrl.clear();
    _typingTimer?.cancel();
    context.read<MessagingBloc>().add(const SetTyping(false));
    context.read<MessagingBloc>().add(SendChatMessage(
          roomId: state.roomId,
          receiverId: state.partnerId,
          content: content,
        ));
    _scrollToBottom();
  }

  Future<void> _pickAndSendAttachment(
      BuildContext context, ChatState state) async {
    final result = await showAttachmentPickerSheet(context);
    if (result == null || !mounted) return;

    context.read<MessagingBloc>().add(SendAttachmentMessage(
          roomId: state.roomId,
          receiverId: state.partnerId,
          filePath: result.file.path,
          attachmentType: result.attachmentType,
          fileName: result.fileName,
          fileSize: result.fileSize,
          mimeType: result.mimeType,
        ));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagingBloc, MessagingState>(
      listenWhen: (prev, curr) {
        if (curr is! ChatState) return false;
        if (prev is! ChatState) return true;
        final prevMsgs = prev.messages;
        final currMsgs = curr.messages;
        if (currMsgs.length != prevMsgs.length) return true;
        if (currMsgs.isEmpty) return false;
        return currMsgs.last.id != prevMsgs.last.id;
      },
      listener: (context, state) {
        if (state is ChatState) {
          context.read<MessagingBloc>().add(MarkChatRead(state.roomId));
        }
      },
      builder: (context, state) {
        if (state is MessagingError) {
          return Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: AppBar(
              backgroundColor: AppColors.darkBg,
              leading: BackButton(color: Colors.white),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        if (state is ChatState) {
          return _buildChatScaffold(context, state);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          body: Column(
            children: [
              _ChatHeader(
                partnerName: widget.initialPartnerName ?? '',
                avatarUrl: widget.initialAvatarUrl,
                isOnline: false,
                lastSeen: null,
              ),
              _EncryptedBanner(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Partner message skeleton
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SkeletonItem(width: 32, height: 32, borderRadius: 16),
                          const SizedBox(width: 8),
                          const SkeletonItem(width: 200, height: 60, borderRadius: 16),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // My message skeleton
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          SkeletonItem(width: 220, height: 80, borderRadius: 16),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Partner message skeleton
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SkeletonItem(width: 32, height: 32, borderRadius: 16),
                          const SizedBox(width: 8),
                          const SkeletonItem(width: 150, height: 50, borderRadius: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatScaffold(BuildContext context, ChatState state) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _ChatHeader(
            partnerName: state.partnerName,
            avatarUrl: state.partnerAvatarUrl,
            isOnline: state.isPartnerOnline,
            lastSeen: state.partnerLastSeen,
          ),
          _EncryptedBanner(),
          Expanded(
            child: state.isInitializing
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : state.messages.isEmpty && !state.isPartnerTyping
                    ? const _EmptyChat()
                    : _MessageList(
                        scrollCtrl: _scrollCtrl,
                        messages: state.messages,
                        currentUserId: state.currentUserId,
                        partnerName: state.partnerName,
                        isPartnerTyping: state.isPartnerTyping,
                        hasMoreMessages: state.hasMoreMessages,
                        isLoadingMore: state.isLoadingMore,
                        uploadProgressMap: state.uploadProgressMap,
                        onRetry: (msg) {
                          final att = msg.attachment;
                          if (att == null || att.localPath == null) return;
                          context.read<MessagingBloc>().add(
                                SendAttachmentMessage(
                                  roomId: state.roomId,
                                  receiverId: state.partnerId,
                                  filePath: att.localPath!,
                                  attachmentType: msg.type,
                                  fileName: att.fileName ?? 'file',
                                  fileSize: att.fileSize ?? 0,
                                  mimeType: att.mimeType,
                                  retryTempId: msg.id,
                                ),
                              );
                        },
                      ),
          ),
          _InputBar(
            controller: _textCtrl,
            isSending: state.isSending,
            onSend: () => _send(context, state),
            onChanged: () => _onInputChanged(context),
            onAttachment: () => _pickAndSendAttachment(context, state),
          ),
        ],
      ),
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ScrollController scrollCtrl;
  final List<MessageEntity> messages;
  final String currentUserId;
  final String partnerName;
  final bool isPartnerTyping;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final Map<String, double> uploadProgressMap;
  final void Function(MessageEntity msg) onRetry;

  const _MessageList({
    required this.scrollCtrl,
    required this.messages,
    required this.currentUserId,
    required this.partnerName,
    required this.isPartnerTyping,
    required this.hasMoreMessages,
    required this.isLoadingMore,
    required this.uploadProgressMap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final partnerInitial =
        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

    final items = <_ListItem>[];

    if (isPartnerTyping) {
      items.add(const _TypingItem());
    }

    DateTime? lastDate;
    for (final msg in messages.reversed) {
      final date =
          DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      items.add(_MessageItem(msg));

      if (lastDate != null && date != lastDate) {
        items.add(_DateItem(lastDate));
      }
      lastDate = date;
    }
    if (lastDate != null) {
      items.add(_DateItem(lastDate));
    }

    final totalCount = items.length + (hasMoreMessages ? 1 : 0);

    return ListView.builder(
      controller: scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        if (hasMoreMessages && i == totalCount - 1) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2)
                  : const SizedBox.shrink(),
            ),
          );
        }

        final item = items[i];

        if (item is _TypingItem) {
          return _TypingBubble(partnerInitial: partnerInitial);
        }

        if (item is _DateItem) {
          return _DateSeparator(date: item.date);
        }

        final msg = (item as _MessageItem).message;
        final isMine = msg.senderId == currentUserId;

        bool isLastInGroup = true;
        if (i > 0 && items[i - 1] is _MessageItem) {
          final newer = (items[i - 1] as _MessageItem).message;
          isLastInGroup = newer.senderId != msg.senderId;
        }

        return _MessageBubble(
          message: msg,
          isMine: isMine,
          isLastInGroup: isLastInGroup,
          partnerInitial: partnerInitial,
          uploadProgress: uploadProgressMap[msg.id],
          onRetry: () => onRetry(msg),
        );
      },
    );
  }
}

abstract class _ListItem {
  const _ListItem();
}

class _TypingItem extends _ListItem {
  const _TypingItem();
}

class _DateItem extends _ListItem {
  final DateTime date;
  const _DateItem(this.date);
}

class _MessageItem extends _ListItem {
  final MessageEntity message;
  const _MessageItem(this.message);
}

// ── Typing bubble ─────────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final String partnerInitial;
  const _TypingBubble({required this.partnerInitial});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -5).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 60, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 6, bottom: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.partnerInitial,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String partnerName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const _ChatHeader({
    required this.partnerName,
    this.avatarUrl,
    required this.isOnline,
    this.lastSeen,
  });

  String get _initials {
    final parts = partnerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';
  }

  String _statusLabel() {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'last seen recently';
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inSeconds < 60) return 'last seen just now';
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'last seen yesterday';
    return 'last seen ${DateFormat('MMM d').format(lastSeen!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.darkBg,
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.transparent,
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 22),
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    partnerName.isNotEmpty ? _initials : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.darkBg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                if (partnerName.isNotEmpty)
                  Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: isOnline
                          ? const Color(0xFF4CAF50)
                          : Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.more_vert,
              color: Colors.white.withOpacity(0.8), size: 22),
        ],
      ),
    );
  }
}

// ── Encrypted banner ──────────────────────────────────────────────────────────

class _EncryptedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, color: Color(0xFF2E7D32), size: 11),
          const SizedBox(width: 5),
          Text(
            'Messages are end-to-end encrypted',
            style: GoogleFonts.inter(
                color: const Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child:
                  Divider(color: Colors.grey.shade300, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _label(),
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
              child:
                  Divider(color: Colors.grey.shade300, thickness: 0.8)),
        ],
      ),
    );
  }
}

// ── Empty chat ────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👋', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Say hello!',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This conversation is end-to-end encrypted.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final bool isLastInGroup;
  final String partnerInitial;
  final double? uploadProgress;
  final VoidCallback onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isLastInGroup,
    required this.partnerInitial,
    this.uploadProgress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? 8 : 2,
        left: isMine ? 60 : 0,
        right: isMine ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (isLastInGroup)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6, bottom: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    partnerInitial,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              )
            else
              const SizedBox(width: 34),
          ],
          _buildBubbleContent(context),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _ImageBubble(
          message: message,
          isMine: isMine,
          isLastInGroup: isLastInGroup,
          uploadProgress: uploadProgress,
          onRetry: onRetry,
        );
      case MessageType.document:
        return _DocumentBubble(
          message: message,
          isMine: isMine,
          isLastInGroup: isLastInGroup,
          uploadProgress: uploadProgress,
          onRetry: onRetry,
        );
      default:
        return _TextBubble(
          message: message,
          isMine: isMine,
          isLastInGroup: isLastInGroup,
        );
    }
  }
}

// ── Text bubble ───────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final bool isLastInGroup;

  const _TextBubble({
    required this.message,
    required this.isMine,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              Radius.circular(isMine ? 18 : (isLastInGroup ? 4 : 18)),
          bottomRight:
              Radius.circular(isMine ? (isLastInGroup ? 4 : 18) : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isMine ? Colors.white : AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 3),
          _StatusRow(message: message, isMine: isMine),
        ],
      ),
    );
  }
}

// ── Image bubble ──────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final bool isLastInGroup;
  final double? uploadProgress;
  final VoidCallback onRetry;

  const _ImageBubble({
    required this.message,
    required this.isMine,
    required this.isLastInGroup,
    this.uploadProgress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final att = message.attachment;
    final heroTag = 'img_${message.id}';

    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              Radius.circular(isMine ? 18 : (isLastInGroup ? 4 : 18)),
          bottomRight:
              Radius.circular(isMine ? (isLastInGroup ? 4 : 18) : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              Radius.circular(isMine ? 18 : (isLastInGroup ? 4 : 18)),
          bottomRight:
              Radius.circular(isMine ? (isLastInGroup ? 4 : 18) : 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: att == null ||
                      att.uploadStatus == UploadStatus.uploading
                  ? null
                  : () => _openPreview(context, att, heroTag),
              child: _ImageContent(
                attachment: att,
                heroTag: heroTag,
                uploadProgress: uploadProgress,
                isFailed: message.status == MessageStatus.failed,
                onRetry: onRetry,
              ),
            ),
            if (message.content.isNotEmpty &&
                !message.content.startsWith('📷'))
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
              child: _StatusRow(message: message, isMine: isMine),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreview(
      BuildContext context, AttachmentEntity att, String heroTag) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ImagePreviewPage(
        imageUrl: att.url.isNotEmpty ? att.url : null,
        localPath: att.localPath,
        heroTag: heroTag,
        mimeType: att.mimeType,
      ),
    ));
  }
}

class _ImageContent extends StatefulWidget {
  final AttachmentEntity? attachment;
  final String heroTag;
  final double? uploadProgress;
  final bool isFailed;
  final VoidCallback onRetry;

  const _ImageContent({
    required this.attachment,
    required this.heroTag,
    this.uploadProgress,
    required this.isFailed,
    required this.onRetry,
  });

  @override
  State<_ImageContent> createState() => _ImageContentState();
}

class _ImageContentState extends State<_ImageContent> {
  // Incrementing this busts the CachedNetworkImage disk/memory cache so a
  // stale 403-era error entry doesn't prevent the image from loading.
  int _loadGeneration = 0;

  @override
  Widget build(BuildContext context) {
    final att = widget.attachment;
    Widget image;

    if (att == null) {
      image = _placeholder();
    } else if (att.localPath != null) {
      // Show the local file while uploading (or on upload failure for retry UI)
      image = Hero(
        tag: widget.heroTag,
        child: Image.file(
          File(att.localPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    } else if (att.url.isNotEmpty) {
      // Use a generation-scoped cache key so that previously cached HTTP errors
      // (e.g. 403 from old Storage rules) don't block display.
      final cacheKey = '${widget.heroTag}_$_loadGeneration';
      image = Hero(
        tag: widget.heroTag,
        child: CachedNetworkImage(
          imageUrl: att.url,
          cacheKey: cacheKey,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: (_, __) => _loadingWidget(),
          errorWidget: (_, __, ___) => _networkErrorWidget(cacheKey),
        ),
      );
    } else {
      image = _placeholder();
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          // Upload progress overlay
          if (widget.uploadProgress != null && !widget.isFailed)
            Container(
              color: Colors.black38,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: widget.uploadProgress,
                        color: Colors.white,
                        strokeWidth: 3,
                        backgroundColor: Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${((widget.uploadProgress ?? 0) * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          // Upload-failed overlay with re-upload retry button
          if (widget.isFailed)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white70, size: 32),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.grey, size: 48),
      ),
    );
  }

  Widget _loadingWidget() {
    return Container(
      height: 200,
      color: Colors.grey.shade100,
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _networkErrorWidget(String cacheKey) {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: Colors.grey, size: 36),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await CachedNetworkImage.evictFromCache(cacheKey);
                if (mounted) setState(() => _loadGeneration++);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  'Tap to reload',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document bubble ───────────────────────────────────────────────────────────

class _DocumentBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final bool isLastInGroup;
  final double? uploadProgress;
  final VoidCallback onRetry;

  const _DocumentBubble({
    required this.message,
    required this.isMine,
    required this.isLastInGroup,
    this.uploadProgress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final att = message.attachment;
    final isFailed = message.status == MessageStatus.failed;
    final isUploading = uploadProgress != null && !isFailed;
    final canOpen = att != null &&
        att.url.isNotEmpty &&
        att.uploadStatus == UploadStatus.uploaded &&
        !isFailed;

    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              Radius.circular(isMine ? 18 : (isLastInGroup ? 4 : 18)),
          bottomRight:
              Radius.circular(isMine ? (isLastInGroup ? 4 : 18) : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: canOpen ? () => _openDoc(context, att!.url) : null,
            child: Row(
              children: [
                // File icon or spinner
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withOpacity(0.18)
                        : AppColors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isUploading
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            value: uploadProgress,
                            strokeWidth: 2.5,
                            color: isMine ? Colors.white : AppColors.blue,
                            backgroundColor: Colors.transparent,
                          ),
                        )
                      : isFailed
                          ? Icon(Icons.error_outline,
                              color: isMine
                                  ? Colors.white70
                                  : AppColors.error,
                              size: 26)
                          : Icon(
                              _docIcon(att?.extensionLabel),
                              color: isMine ? Colors.white : AppColors.blue,
                              size: 26,
                            ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att?.displayName ?? 'Document',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isMine ? Colors.white : AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (att?.extensionLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? Colors.white.withOpacity(0.2)
                                    : AppColors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                att!.extensionLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isMine
                                      ? Colors.white
                                      : AppColors.blue,
                                ),
                              ),
                            ),
                          if (att?.formattedSize.isNotEmpty == true) ...[
                            const SizedBox(width: 6),
                            Text(
                              att!.formattedSize,
                              style: TextStyle(
                                fontSize: 11,
                                color: isMine
                                    ? Colors.white.withOpacity(0.7)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (canOpen)
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: isMine
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textSecondary,
                  ),
              ],
            ),
          ),
          if (isFailed) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 14,
                      color: isMine
                          ? Colors.white
                          : AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to retry',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMine ? Colors.white : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          _StatusRow(message: message, isMine: isMine),
        ],
      ),
    );
  }

  Future<void> _openDoc(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        AppSnackbar.info(context, 'Could not open document');
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  IconData _docIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

// ── Status row (time + ticks) ─────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;

  const _StatusRow({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final textColor = isMine
        ? Colors.white.withOpacity(0.70)
        : Colors.grey.shade500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('h:mm a').format(message.createdAt),
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        if (isMine) ...[
          const SizedBox(width: 3),
          if (message.status == MessageStatus.failed)
            Icon(Icons.error_outline,
                size: 13, color: Colors.redAccent.withOpacity(0.85))
          else
            Icon(
              message.status == MessageStatus.read
                  ? Icons.done_all
                  : Icons.done,
              size: 13,
              color: message.status == MessageStatus.read
                  ? Colors.lightBlueAccent
                  : textColor,
            ),
        ],
      ],
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onChanged;
  final VoidCallback? onAttachment;
  final bool isSending;

  const _InputBar({
    required this.controller,
    required this.onSend,
    this.onChanged,
    this.onAttachment,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 10, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          GestureDetector(
            onTap: onAttachment,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 4, bottom: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: Icon(Icons.attach_file_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 14.5),
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.newline,
                onChanged: (_) => onChanged?.call(),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSending ? Colors.grey.shade300 : AppColors.primary,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
