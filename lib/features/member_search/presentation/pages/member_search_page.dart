import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no
// MemberSearchBloc wiring or backend connectivity. Re-connect it to
// MemberSearchBloc (PINSearchRequested / QRSearchRequested) before shipping.
class MemberSearchPage extends StatefulWidget {
  const MemberSearchPage({super.key});

  @override
  State<MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  int _activeTab = 0; // 0 = SAFEE PIN, 1 = QR Code
  final _pinCtrl = TextEditingController();
  _MemberMock? _result;

  static const _recent = [
    _MemberMock(
      name: 'Sarah Mitchell',
      pin: '#SM-4291',
      avatarEmoji: '🐱',
      avatarBg: Color(0xFFDCEBFF),
      badgeLabel: 'L2 Verified',
      badgeColor: AppColors.blue,
      trustScore: 96,
      safetyRating: 4.9,
      meetings: 38,
      level1: true,
      level2: true,
      bio: 'Verified member who loves meeting new people safely. Frequent '
          'coffee meetups in the downtown area.',
      reviewAuthor: 'James C.',
      reviewDate: 'Jun 9',
      reviewRating: 5,
      reviewText: 'Sarah was incredibly professional and trustworthy. Felt '
          'completely safe during our meeting.',
    ),
    _MemberMock(
      name: 'James Carter',
      pin: '#JC-8834',
      avatarEmoji: '🦁',
      avatarBg: Color(0xFFDFF5E3),
      badgeLabel: 'L1 Verified',
      badgeColor: AppColors.success,
      trustScore: 88,
      safetyRating: 4.7,
      meetings: 22,
      level1: true,
      level2: false,
      bio: 'Identity verified member, usually meets up for business and '
          'networking coffee chats.',
      reviewAuthor: 'Emily T.',
      reviewDate: 'Jun 2',
      reviewRating: 5,
      reviewText: 'James was punctual and friendly. Great experience '
          'meeting up for coffee.',
    ),
    _MemberMock(
      name: 'Emily Torres',
      pin: '#ET-2217',
      avatarEmoji: '👩',
      avatarBg: Color(0xFFFCEFC7),
      badgeLabel: 'Pro',
      badgeColor: AppColors.warning,
      trustScore: 91,
      safetyRating: 4.8,
      meetings: 15,
      level1: true,
      level2: true,
      bio: 'Premium member with a fully completed background check. Open to '
          'marketplace meetups.',
      reviewAuthor: 'Sarah M.',
      reviewDate: 'May 28',
      reviewRating: 5,
      reviewText: 'Emily was warm and easy to talk to. Highly recommend '
          'meeting her.',
    ),
  ];

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _search() {
    if (_pinCtrl.text.trim().isEmpty) return;
    setState(() => _result = _recent.first);
  }

  void _simulateScan() {
    setState(() => _result = _recent.first);
  }

  void _selectRecent(_MemberMock member) {
    setState(() {
      _pinCtrl.text = member.pin.replaceFirst('#', '');
      _result = member;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
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
                  if (_activeTab == 0) _buildPinTab() else _buildQrTab(),
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _MemberResultCard(member: _result!),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'RECENT SEARCHES',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._recent.map((m) => _RecentSearchRow(member: m, onTap: () => _selectRecent(m))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinTab() {
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
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _pinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter SAFEE PIN (e.g. SM-7821)',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SearchButton(label: 'Search Member', onTap: _search),
      ],
    );
  }

  Widget _buildQrTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              CustomPaint(
                painter: _DashedRectPainter(color: AppColors.border),
                child: Container(
                  width: 240,
                  height: 240,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.qr_code_2, color: AppColors.textTertiary, size: 72),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Point camera at QR code',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Camera will activate automatically',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SearchButton(label: 'Simulate Scan', onTap: _simulateScan),
      ],
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
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
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
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16));
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
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
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.textPrimary : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? AppColors.textPrimary : AppColors.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  final _MemberMock member;
  final VoidCallback onTap;
  const _RecentSearchRow({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: member.avatarBg, shape: BoxShape.circle),
              child: Center(child: Text(member.avatarEmoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('PIN: ${member.pin}', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: member.badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.badgeLabel,
                style: GoogleFonts.inter(color: member.badgeColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberMock {
  final String name;
  final String pin;
  final String avatarEmoji;
  final Color avatarBg;
  final String badgeLabel;
  final Color badgeColor;
  final int trustScore;
  final double safetyRating;
  final int meetings;
  final bool level1;
  final bool level2;
  final String bio;
  final String reviewAuthor;
  final String reviewDate;
  final int reviewRating;
  final String reviewText;

  const _MemberMock({
    required this.name,
    required this.pin,
    required this.avatarEmoji,
    required this.avatarBg,
    required this.badgeLabel,
    required this.badgeColor,
    required this.trustScore,
    required this.safetyRating,
    required this.meetings,
    required this.level1,
    required this.level2,
    required this.bio,
    required this.reviewAuthor,
    required this.reviewDate,
    required this.reviewRating,
    required this.reviewText,
  });
}

class _MemberResultCard extends StatelessWidget {
  final _MemberMock member;
  const _MemberResultCard({required this.member});

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
              Container(
                height: 96,
                decoration: BoxDecoration(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.military_tech, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Trust Score ${member.trustScore}',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.darkBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.person, color: Colors.white54, size: 30),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 64,
                child: Row(
                  children: [
                    _PillButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Message',
                      filled: true,
                      onTap: () => context.push('${AppRoutes.chat}?memberId=${member.pin}'),
                    ),
                    const SizedBox(width: 8),
                    _PillButton(
                      icon: Icons.calendar_today_outlined,
                      label: 'Meet',
                      filled: false,
                      onTap: () => context.push('${AppRoutes.meetingSetup}?memberId=${member.pin}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('SAFEE PIN: ${member.pin}', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
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
                        value: '${member.safetyRating}★',
                        label: 'Safety Rating',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value: '${member.meetings}',
                        label: 'Meetings',
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (member.level1) _VerifiedPill(label: 'Level 1 Verified', color: AppColors.success),
                    if (member.level1 && member.level2) const SizedBox(width: 8),
                    if (member.level2) _VerifiedPill(label: 'Level 2 Verified', color: AppColors.blue),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ABOUT',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(member.bio, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LATEST REVIEW',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < member.reviewRating ? Icons.star : Icons.star_border,
                                color: AppColors.warning,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '"${member.reviewText}"',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '— ${member.reviewAuthor}, ${member.reviewDate}',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
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

  const _PillButton({required this.icon, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: filled ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  final String label;
  final Color color;
  const _VerifiedPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
