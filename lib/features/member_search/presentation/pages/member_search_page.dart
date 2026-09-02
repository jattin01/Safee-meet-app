import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/skeleton_item.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';
import '../../../messaging/domain/entities/message_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../../subscription/presentation/cubit/current_subscription_cubit.dart';
import '../bloc/member_search_bloc.dart';
import 'package:safee_meet/core/shared/widgets/app_snackbar.dart';

class MemberSearchPage extends StatelessWidget {
  /// When true, tapping "Meet" returns the selected [MemberEntity] to the
  /// caller via [Navigator.pop] instead of pushing to Create Meeting —
  /// used when this page is opened to pick a meeting partner.
  final bool pickerMode;

  /// Which tab to open on ('qr' opens the QR Scanner tab directly; anything
  /// else, including null, defaults to the Safee PIN tab).
  final String? initialTab;
  const MemberSearchPage({super.key, this.pickerMode = false, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<MemberSearchBloc>(),
      child: _MemberSearchView(pickerMode: pickerMode, initialTab: initialTab),
    );
  }
}

class _MemberSearchView extends StatefulWidget {
  final bool pickerMode;
  final String? initialTab;
  const _MemberSearchView({required this.pickerMode, this.initialTab});

  @override
  State<_MemberSearchView> createState() => _MemberSearchViewState();
}

class _MemberSearchViewState extends State<_MemberSearchView> {
  late int _activeTab = widget.initialTab == 'qr' ? 1 : 0;
  final _pinCtrl = TextEditingController();
  final _scannerController = MobileScannerController(autoStart: false);
  final _imagePicker = ImagePicker();
  bool _qrHandled = false;
  bool _resolvingGalleryImage = false;
  final _resultSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Reset search state on open
    context.read<MemberSearchBloc>().add(const MemberSearchReset());

    // If opened directly on the QR tab, start the scanner
    if (_activeTab == 1) {
      _scannerController.start();
    }

    // Clear old result/error when user types a new PIN
    _pinCtrl.addListener(() {
      final state = context.read<MemberSearchBloc>().state;
      if (state is MemberSearchError || state is MemberSearchFound) {
        context.read<MemberSearchBloc>().add(const MemberSearchReset());
      }
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    // Always stop before disposing — MobileScanner's SurfaceView continues
    // producing frames until stop() is called. Without this, navigating away
    // from the page leaves the camera producing frames into a detached
    // SurfaceView, which exhausts Android's BLASTBufferQueue (max 7 frames).
    _scannerController.stop();
    _scannerController.dispose();
    super.dispose();
  }

  void _search() {
    final pin = _pinCtrl.text.trim().toUpperCase();
    if (pin.length != 10 || !pin.startsWith('SM')) return;
    context.read<MemberSearchBloc>().add(PINSearchRequested(pin));
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_qrHandled || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    _qrHandled = true;
    _scannerController.stop(); // Stop camera to prevent buffer exhaustion while viewing results
    context.read<MemberSearchBloc>().add(QRSearchRequested(code));
  }

  void _rescan() {
    setState(() => _qrHandled = false);
    _scannerController.start();
    context.read<MemberSearchBloc>().add(const MemberSearchReset());
  }

  // Mirrors the camera path (_onQrDetect): decodes the picked image and, if
  // it contains a valid code, dispatches the exact same QRSearchRequested
  // event — so the backend's subscription/search-limit validation applies
  // identically regardless of how the QR was captured.
  Future<void> _pickFromGallery() async {
    if (_qrHandled || _resolvingGalleryImage) return;

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _resolvingGalleryImage = true);
    try {
      final result = await _scannerController.analyzeImage(picked.path);
      final barcodes = result?.barcodes ?? const [];
      final code = barcodes.isNotEmpty ? barcodes.first.rawValue?.trim() : null;

      if (!mounted) return;
      if (code == null || code.isEmpty) {
        setState(() => _resolvingGalleryImage = false);
        AppSnackbar.info(
            context, 'No valid QR code found in the selected image.');
        return;
      }

      setState(() {
        _qrHandled = true;
        _resolvingGalleryImage = false;
      });
      context.read<MemberSearchBloc>().add(QRSearchRequested(code));
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingGalleryImage = false);
      AppSnackbar.info(
          context, 'No valid QR code found in the selected image.');
    }
  }

  void _selectRecent(MemberEntity member) {
    context.read<MemberSearchBloc>().add(RecentMemberSelected(member));
  }

  // The result/error card renders below "Recently Searched", whose height
  // varies with the list, so it can land off-screen after a search — scroll
  // it into view once the bloc settles on a result, regardless of whether
  // the search came from the PIN field or the QR/gallery scanner.
  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _resultSectionKey.currentContext;
      if (resultContext == null) return;
      Scrollable.ensureVisible(
        resultContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  // Returns the push's Future (resolves once the pushed screen is popped)
  // rather than firing-and-forgetting it, so _MemberResultCard can keep its
  // Message/Meet buttons disabled for exactly as long as that navigation is
  // "in flight" — the push itself still starts immediately/synchronously,
  // this only changes when the caller finds out it's done.
  Future<void> _openChat(BuildContext ctx, MemberEntity member) async {
    _scannerController.stop();
    await ctx.push(
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
    if (mounted && _activeTab == 1 && !_qrHandled) {
      _scannerController.start();
    }
  }

  Future<void> _openMeeting(BuildContext ctx, MemberEntity member) async {
    if (widget.pickerMode) {
      Navigator.of(ctx).pop(member);
      return;
    }

    final user = ctx.read<CurrentUserCubit>().state.profile;
    final plan = ctx.read<CurrentSubscriptionCubit>().state.subscription?.plan;

    if (user != null && plan != null) {
      final historyLimit = plan.getFeatureLimit('meeting_history');
      if (historyLimit != null && user.totalMeetings >= historyLimit) {
        await showDialog(
          context: ctx,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: _UpgradeLimitCard(
              message: 'You have reached your limit of $historyLimit meetings for this plan.',
              onTap: () async {
                // Pop the dialog with its own (builder-scoped) context, but
                // push the next route with the outer page context (`ctx`),
                // not this one — `context` here belongs to the dialog that's
                // being removed, and reusing it for a second navigation
                // right after popping it risks Flutter's "element is
                // already inactive" crash. `ctx` stays valid for as long as
                // this page itself is alive.
                Navigator.pop(context);
                _scannerController.stop();
                await ctx.push(AppRoutes.subscription, extra: 'basic_unlimited');
                if (mounted && _activeTab == 1 && !_qrHandled) {
                  _scannerController.start();
                }
              },
            ),
          ),
        );
        return;
      }
    }

    _scannerController.stop();
    await ctx.push('${AppRoutes.meetingSetup}?memberId=${member.id}', extra: member);
    if (mounted && _activeTab == 1 && !_qrHandled) {
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocConsumer<MemberSearchBloc, MemberSearchState>(
        listener: (context, state) {
          if (state is MemberSearchLoading ||
              state is MemberSearchFound ||
              state is MemberSearchError) {
            _scrollToResult();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final bloc = context.read<MemberSearchBloc>();
              
              // We want to wait for whichever loading state is applicable to finish
              final future = bloc.stream.firstWhere(
                (s) => !s.isLoadingRecentSearches && s is! MemberSearchLoading,
              );
              
              if (state is MemberSearchFound) {
                bloc.add(PINSearchRequested(state.member.safeePIN));
              } else {
                bloc.add(const RecentSearchesRequested());
              }
              
              await future;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarkScreenHeader(
                  title: 'Search Member',
                  childGap: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TabPillRow(
                        activeTab: _activeTab,
                        onTabChanged: (i) {
                          if (_activeTab != i) {
                            if (i == 1 && !_qrHandled) {
                              _scannerController.start();
                            } else {
                              _scannerController.stop();
                            }
                            setState(() => _activeTab = i);
                            context.read<MemberSearchBloc>().add(MemberSearchReset());
                            if (i == 1) {
                              _pinCtrl.clear();
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_activeTab == 0)
                        _buildPinTab(state)
                      else
                        _buildQrTab(state),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 24, 20, context.bottomSafePadding(32)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RecentSearchesSection(
                        members: state.recentSearches,
                        isLoading: state.isLoadingRecentSearches,
                        selectedMemberId:
                            state is MemberSearchFound ? state.member.id : null,
                        onSelect: _selectRecent,
                      ),

                      // Result or loading
                      Column(
                        key: _resultSectionKey,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            (state.upgradeRequired ||
                                    state.message.toLowerCase().contains('limit') ||
                                    state.message.toLowerCase().contains('upgrade') ||
                                    state.message.toLowerCase().contains('subscription'))
                                ? _UpgradeLimitCard(
                                    message: state.message,
                                    onTap: () =>
                                        context.push(AppRoutes.subscription, extra: 'basic_unlimited'),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32, horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.error.withValues(alpha: 0.1)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.error.withValues(alpha: 0.05),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.person_off_outlined,
                                              color: AppColors.error, size: 32),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          state.message,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Double-check the PIN or ask the person to share their QR code.',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.textTertiary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                        ],
                      ),

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
                            'Or switch to the QR Scanner tab and scan their profile QR code.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ));
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
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
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _pinCtrl,
          builder: (context, value, child) {
            final pin = value.text.trim().toUpperCase();
            final isValid = pin.isNotEmpty;
            return _SearchButton(
              label: state is MemberSearchLoading ? 'Searching...' : 'Search Member',
              onTap: (!isValid || state is MemberSearchLoading) ? null : _search,
            );
          },
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
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
            ] else ...[
              const SizedBox(height: 20),
              _OrDivider(),
              const SizedBox(height: 16),
              _GalleryButton(
                loading: _resolvingGalleryImage,
                onTap: _pickFromGallery,
              ),
            ],
          ]),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('OR',
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ]),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GalleryButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          color: AppColors.textPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text('Choose from Gallery',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Upgrade your plan to unlock more SAFEE PIN searches.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade Plan',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
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
  // While true, the fetch behind [members] hasn't resolved yet — show a
  // spinner in its place instead of silently rendering nothing (which
  // looked identical to "no recent searches" and made the screen feel
  // unresponsive on first open).
  final bool isLoading;
  final String? selectedMemberId;
  final ValueChanged<MemberEntity> onSelect;
  const _RecentSearchesSection({
    required this.members,
    this.isLoading = false,
    this.selectedMemberId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Once resolved, an empty list still means nothing to show — same as
    // before. Only collapse to nothing when we're sure there's neither a
    // fetch in flight nor any data.
    if (!isLoading && members.isEmpty) return const SizedBox.shrink();
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
        if (isLoading)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(
                2,
                (index) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const SkeletonItem(
                              width: 40, height: 40, borderRadius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SkeletonItem(width: 120, height: 14),
                                SizedBox(height: 6),
                                SkeletonItem(width: 80, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index == 0)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  _RecentMemberTile(
                    member: members[i],
                    isSelected: members[i].id == selectedMemberId,
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
  final bool isSelected;
  final VoidCallback onTap;
  const _RecentMemberTile({
    required this.member,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
          border: isSelected
              ? Border(left: BorderSide(color: AppColors.primary, width: 3))
              : null,
        ),
        padding: EdgeInsets.fromLTRB(isSelected ? 11 : 14, 10, 14, 10),
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
                    child: Image.network(member.avatarUrl!, fit: BoxFit.cover),
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('PIN: ${member.safeePIN}',
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          isSelected
              ? Icon(Icons.check_circle, color: AppColors.primary, size: 18)
              : Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
        ]),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SearchButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.border : null,
          gradient: isDisabled 
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDisabled ? [] : [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                  color: isDisabled ? AppColors.textTertiary : Colors.white,
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
              label: 'QR Scanner',
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

class _MemberResultCard extends StatefulWidget {
  final MemberEntity member;
  final Future<void> Function() onChat;
  final Future<void> Function() onMeet;

  const _MemberResultCard({
    required this.member,
    required this.onChat,
    required this.onMeet,
  });

  @override
  State<_MemberResultCard> createState() => _MemberResultCardState();
}

class _MemberResultCardState extends State<_MemberResultCard> {
  // Independent per-button in-flight flags — tapping one only disables that
  // button and swaps in its own spinner; the other stays fully interactive
  // the whole time, per design. Each resets automatically once its own
  // pushed screen is popped (or, for the picker/limit-dialog branches inside
  // onMeet, once that resolves).
  bool _chatPending = false;
  bool _meetPending = false;

  Future<void> _handleChatTap() async {
    if (_chatPending) return;
    setState(() => _chatPending = true);
    try {
      await widget.onChat();
    } finally {
      if (mounted) setState(() => _chatPending = false);
    }
  }

  Future<void> _handleMeetTap() async {
    if (_meetPending) return;
    setState(() => _meetPending = true);
    try {
      await widget.onMeet();
    } finally {
      if (mounted) setState(() => _meetPending = false);
    }
  }

  Widget _spinner(Color color) => SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.darkBg, Color(0xFF1A1F2B)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('SAFEE PIN: ${member.safeePIN}',
                                  style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              if (member.badges.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: member.badges
                                      .map((b) => _MiniBadge(b))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Trust Score Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.military_tech,
                                color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text('Trust: ${member.trustScore}',
                                style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: '${member.trustScore}',
                            label: 'Trust',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            value: '${member.safetyScore}',
                            label: 'Safety',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            value: '${member.totalMeetings}',
                            label: 'Meetings',
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _chatPending ? null : _handleChatTap,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _chatPending
                                ? _spinner(AppColors.textPrimary)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline, size: 16),
                                      const SizedBox(width: 6),
                                      Text('Message',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _meetPending ? null : _handleMeetTap,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              // Without these, Material 3's default disabled
                              // style kicks in the instant onPressed becomes
                              // null — washed-out grey background and
                              // dimmed icon. That reads as the button
                              // vanishing rather than a clean "disabled,
                              // loading" state, so pin it to look identical
                              // to the enabled style while the spinner shows.
                              disabledBackgroundColor: AppColors.primary,
                              disabledForegroundColor: Colors.white,
                              disabledIconColor: Colors.white,
                            ).copyWith(
                              // styleFrom's `elevation` param hardcodes the
                              // disabled state's elevation to 0 (dropping the
                              // shadow) with no styleFrom param to override
                              // it — this copyWith forces it back to the
                              // same elevation in every state instead.
                              elevation: const WidgetStatePropertyAll(2),
                            ),
                            child: _meetPending
                                ? _spinner(Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text('Meet',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Avatar
          Positioned(
            top: 36,
            left: 16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: member.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(member.avatarUrl!,
                          fit: BoxFit.cover),
                    )
                  : Center(
                      child: Text(member.initials,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _MiniBadge extends StatelessWidget {
  final String label;
  const _MiniBadge(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold)));
  }
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
