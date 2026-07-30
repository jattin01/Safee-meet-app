import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../messaging/domain/entities/message_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../bloc/member_search_bloc.dart';

class MemberSearchPage extends StatelessWidget {
  /// When true, tapping "Meet" returns the selected [MemberEntity] to the
  /// caller via [Navigator.pop] instead of pushing to Create Meeting —
  /// used when this page is opened to pick a meeting partner.
  final bool pickerMode;
  const MemberSearchPage({super.key, this.pickerMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MemberSearchBloc>()..add(const RecentSearchesRequested()),
      child: _MemberSearchView(pickerMode: pickerMode),
    );
  }
}

class _MemberSearchView extends StatefulWidget {
  final bool pickerMode;
  const _MemberSearchView({required this.pickerMode});

  @override
  State<_MemberSearchView> createState() => _MemberSearchViewState();
}

class _MemberSearchViewState extends State<_MemberSearchView> {
  int _activeTab = 0;
  final _pinCtrl = TextEditingController();
  final _scannerController = MobileScannerController();
  bool _qrHandled = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _search() {
    final pin = _pinCtrl.text.trim().toUpperCase();
    if (pin.isEmpty) return;
    context.read<MemberSearchBloc>().add(PINSearchRequested(pin));
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_qrHandled || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    _qrHandled = true;
    context.read<MemberSearchBloc>().add(QRSearchRequested(code));
  }

  void _rescan() {
    setState(() => _qrHandled = false);
    context.read<MemberSearchBloc>().add(const MemberSearchReset());
  }

  void _selectRecent(MemberEntity member) {
    context.read<MemberSearchBloc>().add(RecentMemberSelected(member));
  }

  void _openChat(BuildContext ctx, MemberEntity member) {
    ctx.push(
      '${AppRoutes.chat}/new_${member.id}',
      extra: ConversationEntity(
        id: 'new_${member.id}',
        partnerId: member.id,
        partnerName: member.name,
        partnerAvatarUrl: member.avatarUrl,
        partnerVerificationLevel: member.verificationLevel,
        unreadCount: 0,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _openMeeting(BuildContext ctx, MemberEntity member) {
    if (widget.pickerMode) {
      Navigator.of(ctx).pop(member);
      return;
    }
    ctx.push('${AppRoutes.meetingSetup}?memberId=${member.id}', extra: member);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocBuilder<MemberSearchBloc, MemberSearchState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarkScreenHeader(
                  title: 'Search Member',
                  childGap: 20,
                  child: _TabPillRow(
                    activeTab: _activeTab,
                    onTabChanged: (i) => setState(() => _activeTab = i),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_activeTab == 0)
                        _buildPinTab(state)
                      else
                        _buildQrTab(state),

                      _RecentSearchesSection(
                        members: state.recentSearches,
                        onSelect: _selectRecent,
                      ),

                      // Result or loading
                      if (state is MemberSearchLoading) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ] else if (state is MemberSearchFound) ...[
                        const SizedBox(height: 24),
                        _MemberResultCard(
                          member: state.member,
                          onChat: () => _openChat(context, state.member),
                          onMeet: () => _openMeeting(context, state.member),
                        ),
                      ] else if (state is MemberSearchError) ...[
                        const SizedBox(height: 24),
                        state.upgradeRequired
                            ? _UpgradeLimitCard(
                                message: state.message,
                                onTap: () =>
                                    context.push(AppRoutes.subscription),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.error
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(children: [
                                  Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(state.message,
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 14)),
                                  ),
                                ]),
                              ),
                      ],

                      const SizedBox(height: 28),
                      Text(
                        'HOW TO FIND A MEMBER',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HintCard(
                        icon: Icons.person_search,
                        text:
                            'Ask the other person for their SAFEE PIN (e.g. SMHIPZTWPS) and type it above.',
                      ),
                      const SizedBox(height: 8),
                      _HintCard(
                        icon: Icons.qr_code_2,
                        text:
                            'Or switch to the QR tab and scan their profile QR code.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinTab(MemberSearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Icon(Icons.search, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _pinCtrl,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _search(),
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 15),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter SAFEE PIN (e.g. SMHIPZTWPS)',
                  hintStyle:
                      TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _SearchButton(
          label:
              state is MemberSearchLoading ? 'Searching...' : 'Search Member',
          onTap: state is MemberSearchLoading ? () {} : _search,
        ),
      ],
    );
  }

  Widget _buildQrTab(MemberSearchState state) {
    final resolved = state is MemberSearchFound || state is MemberSearchError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            CustomPaint(
              painter: _DashedRectPainter(color: AppColors.border),
              child: Container(
                width: 240,
                height: 240,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 224,
                    height: 224,
                    child: resolved
                        ? Container(
                            color: AppColors.cardBg,
                            child: Icon(Icons.qr_code_2,
                                color: AppColors.textTertiary, size: 72),
                          )
                        : MobileScanner(
                            controller: _scannerController,
                            onDetect: _onQrDetect,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              resolved ? 'Scan complete' : 'Point camera at QR code',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              resolved
                  ? 'Scan a different code below'
                  : 'Align the QR code within the frame',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (resolved) ...[
              const SizedBox(height: 16),
              _SearchButton(label: 'Scan Again', onTap: _rescan),
            ],
          ]),
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _UpgradeLimitCard extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _UpgradeLimitCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: AppColors.error, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.error, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HintCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ),
        ]),
      );
}

class _RecentSearchesSection extends StatelessWidget {
  final List<MemberEntity> members;
  final ValueChanged<MemberEntity> onSelect;
  const _RecentSearchesSection({required this.members, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'RECENTLY SEARCHED',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < members.length; i++) ...[
                _RecentMemberTile(
                  member: members[i],
                  onTap: () => onSelect(members[i]),
                ),
                if (i != members.length - 1)
                  Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentMemberTile extends StatelessWidget {
  final MemberEntity member;
  final VoidCallback onTap;
  const _RecentMemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: member.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        Image.network(member.avatarUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(member.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('PIN: ${member.safeePIN}',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
        ]),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SearchButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dash = 6.0, gap = 5.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TabPillRow extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  const _TabPillRow({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: _TabPill(
              icon: Icons.search,
              label: 'SAFEE PIN',
              active: activeTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TabPill(
              icon: Icons.qr_code_2,
              label: 'QR Code',
              active: activeTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ]),
      );
}

class _TabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabPill(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 16,
                color: active ? AppColors.textPrimary : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                  color:
                      active ? AppColors.textPrimary : AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      );
}

// ── Real Member Result Card ───────────────────────────────────────────────────

class _MemberResultCard extends StatelessWidget {
  final MemberEntity member;
  final VoidCallback onChat;
  final VoidCallback onMeet;

  const _MemberResultCard({
    required this.member,
    required this.onChat,
    required this.onMeet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Header gradient
              Container(
                height: 96,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.blue, AppColors.blueLight],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.military_tech,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Trust Score ${member.trustScore}',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
              // Avatar
              Positioned(
                left: 16,
                top: 64,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: member.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(member.avatarUrl!,
                              fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(member.initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                        ),
                ),
              ),
              // Action buttons
              Positioned(
                right: 16,
                top: 64,
                child: Row(children: [
                  _PillButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Message',
                    filled: true,
                    onTap: onChat,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    icon: Icons.calendar_today_outlined,
                    label: 'Meet',
                    filled: false,
                    onTap: onMeet,
                  ),
                ]),
              ),
            ],
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('SAFEE PIN: ${member.safeePIN}',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _StatTile(
                      value: '${member.trustScore}',
                      label: 'Trust Score',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${member.rating.toStringAsFixed(1)}★',
                      label: 'Safety Rating',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${member.totalMeetings}',
                      label: 'Meetings',
                      color: AppColors.blue,
                    ),
                  ),
                ]),
                if (member.verificationLevel != 'none') ...[
                  const SizedBox(height: 16),
                  _VerifiedPill(
                    label: '${member.verificationLevel.toUpperCase()} Tier',
                    color: member.verificationLevel == 'high'
                        ? AppColors.blue
                        : AppColors.success,
                  ),
                ],
                if (member.badges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: member.badges
                        .map((b) =>
                            _VerifiedPill(label: b, color: AppColors.primary))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _PillButton(
      {required this.icon,
      required this.label,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 14, color: filled ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                  color: filled ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      );
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
      );
}

class _VerifiedPill extends StatelessWidget {
  final String label;
  final Color color;
  const _VerifiedPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}
