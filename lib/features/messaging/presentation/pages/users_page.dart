import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../bloc/messaging_bloc.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MessagingBloc>()..add(const FetchUsers()),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startChat(BuildContext context, UserProfileEntity user) {
    final conversation = ConversationEntity(
      id: user.uid,
      partnerId: user.uid,
      partnerName: user.name,
      partnerAvatarUrl: user.avatarUrl,
      partnerVerificationLevel: 'none',
      unreadCount: 0,
      updatedAt: DateTime.now(),
    );
    context.push('${AppRoutes.chat}/${user.uid}', extra: conversation);
  }

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<MessagingBloc>();
    final done =
        bloc.stream.firstWhere((s) => s is UsersLoaded || s is MessagingError);
    bloc.add(const FetchUsers());
    return done;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'New Chat',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name…',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withOpacity(0.6), size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<MessagingBloc, MessagingState>(
        builder: (context, state) {
          if (state is MessagingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is MessagingError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<MessagingBloc>().add(const FetchUsers()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is UsersLoaded) {
            final filtered = _query.isEmpty
                ? state.users
                : state.users
                    .where((u) => u.name.toLowerCase().contains(_query))
                    .toList();

            if (filtered.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _refresh(context),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search,
                                color: AppColors.textTertiary, size: 56),
                            const SizedBox(height: 16),
                            Text(
                              _query.isEmpty
                                  ? 'No users yet'
                                  : 'No results for "$_query"',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 15),
                            ),
                            if (_query.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Users appear here once they sign in.',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(context),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserTile(
                    user: filtered[i],
                    onTap: () => _startChat(context, filtered[i])),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserProfileEntity user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.initials,
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
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (user.email != null && user.email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email!,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
