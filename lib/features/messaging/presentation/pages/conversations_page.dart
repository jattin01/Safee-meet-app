import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/messaging_bloc.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagingBloc>()..add(const FetchConversations()),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatefulWidget {
  const _ConversationsView();

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late final PresenceService _presence;

  @override
  void initState() {
    super.initState();
    _presence = sl<PresenceService>();
    _presence.startListening();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _presence.stopListening();
    super.dispose();
  }

  void _showConversationOptions(
      BuildContext context, ConversationEntity conv) {
    final bloc = context.read<MessagingBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(
              conv.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin,
              color: AppColors.primary,
            ),
            title: Text(
              conv.isPinned ? 'Unpin conversation' : 'Pin conversation',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              bloc.add(
                  PinConversation(roomId: conv.id, pin: !conv.isPinned));
            },
          ),
          ListTile(
            leading: Icon(
              conv.isMuted
                  ? Icons.notifications_outlined
                  : Icons.notifications_off_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              conv.isMuted ? 'Unmute notifications' : 'Mute notifications',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              bloc.add(
                  MuteConversation(roomId: conv.id, mute: !conv.isMuted));
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocBuilder<MessagingBloc, MessagingState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<MessagingBloc>().add(const FetchConversations()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DarkScreenHeader(
                    title: 'Secure Messages',
                    childGap: 10,
                    child: _EncryptionNotice(),
                  ),
                  // Search bar
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase()),
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Search conversations…',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade500, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: Icon(Icons.close,
                                    color: Colors.grey.shade600, size: 18),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.border, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.border, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  _buildBody(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MessagingState state) {
    if (state is MessagingLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state is MessagingError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context
                  .read<MessagingBloc>()
                  .add(const FetchConversations()),
              child: Text('Retry',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    if (state is ConversationsState) {
      // Sort: pinned first, then by updatedAt
      final sorted = [
        ...state.conversations.where((c) => c.isPinned),
        ...state.conversations.where((c) => !c.isPinned),
      ];

      // Apply search filter
      final filtered = _query.isEmpty
          ? sorted
          : sorted
              .where((c) =>
                  c.partnerName.toLowerCase().contains(_query) ||
                  (c.lastMessage?.content.toLowerCase().contains(_query) ??
                      false))
              .toList();

      if (filtered.isEmpty) {
        return _query.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.search_off,
                        color: AppColors.textTertiary, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No results for "$_query"',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              )
            : const _EmptyState();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: filtered
              .map((c) => _ConversationTile(
                    conversation: c,
                    onLongPress: () =>
                        _showConversationOptions(context, c),
                  ))
              .toList(),
        ),
      );
    }

    return const _EmptyState();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _EncryptionNotice extends StatelessWidget {
  const _EncryptionNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock, color: AppColors.textTertiary, size: 13),
        const SizedBox(width: 6),
        Text(
          'All chats are end-to-end encrypted',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline,
              color: AppColors.textTertiary, size: 56),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your conversations will appear here.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback? onLongPress;

  const _ConversationTile({
    required this.conversation,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final lastMsg = conversation.lastMessage;
    final timeLabel = lastMsg != null ? _formatTime(lastMsg.createdAt) : '';

    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.chat}/${conversation.id}',
        extra: conversation,
      ),
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: conversation.isPinned
              ? AppColors.primary.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withOpacity(0.3)
                : (conversation.isPinned
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.partnerInitials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (conversation.isPinned) ...[
                        Icon(Icons.push_pin,
                            size: 12,
                            color: AppColors.primary.withOpacity(0.7)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.partnerName,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg?.content ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (conversation.isMuted)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.notifications_off_outlined,
                            size: 14,
                            color: AppColors.textTertiary),
                      ),
                    if (hasUnread)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${conversation.unreadCount > 9 ? '9+' : conversation.unreadCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
