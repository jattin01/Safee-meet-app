import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/app_logo_widget.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/info_banner.dart';
import '../../../../core/shared/widgets/otp_input_widget.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../../../core/shared/widgets/segmented_bar.dart';

enum _AccountType { normalUser, employer }

// PROTOTYPE MODE: step validation and AuthBloc/network wiring are
// intentionally disabled so every step can be reached and tested.
// Re-enable validation and hook this page up to AuthBloc before shipping.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ── Account type ────────────────────────────────────────────────────────────
  _AccountType? _accountType; // null = type not yet chosen

  // ── Shared fields ───────────────────────────────────────────────────────────
  int _step = 1;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // ── Employer-only fields ────────────────────────────────────────────────────
  final _companyNameCtrl = TextEditingController();
  final _employerIdCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();

  // ── Derived helpers ─────────────────────────────────────────────────────────
  bool get _isEmployer => _accountType == _AccountType.employer;
  int get _totalSteps => _isEmployer ? 7 : 6;

  static const List<String> _sharedTitles = [
    'Your Name',
    'Mobile Number',
    'Verify Mobile',
    'Email Address',
    'Verify Email',
    'Create Password',
  ];

  String get _stepTitle {
    if (_isEmployer) {
      const employerTitles = [
        'Your Name',
        'Mobile Number',
        'Verify Mobile',
        'Email Address',
        'Verify Email',
        'Company Details',
        'Create Password',
      ];
      return employerTitles[_step - 1];
    }
    return _sharedTitles[_step - 1];
  }

  // ── Password strength ───────────────────────────────────────────────────────
  double get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= AppConstants.passwordMinLength) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(p)) score++;
    return score / 4;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s < 0.25) return AppColors.error;
    if (s < 0.5) return AppColors.warning;
    if (s < 0.75) return AppColors.blue;
    return AppColors.success;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s < 0.25) return 'Weak password';
    if (s < 0.5) return 'Fair password';
    if (s < 0.75) return 'Good password';
    return 'Strong password';
  }

  // ── Button helpers ──────────────────────────────────────────────────────────
  String get _buttonLabel {
    switch (_step) {
      case 2:
      case 4:
        return 'Send OTP';
      case 3:
      case 5:
        return 'Verify';
      case 6:
        return _isEmployer ? 'Next' : 'Create Account';
      case 7:
        return 'Create Account';
      default:
        return 'Next';
    }
  }

  bool get _buttonLooksDisabled {
    switch (_step) {
      case 1:
        return _nameCtrl.text.trim().isEmpty;
      case 2:
        return _phoneCtrl.text.trim().isEmpty;
      case 4:
        return _emailCtrl.text.trim().isEmpty;
      case 6:
        if (_isEmployer) {
          return _companyNameCtrl.text.trim().isEmpty ||
              _employerIdCtrl.text.trim().isEmpty;
        }
        return false;
      default:
        return false;
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  void _onNext(BuildContext context) {
    if (_step < _totalSteps) {
      setState(() => _step++);
      return;
    }
    context.go(AppRoutes.dashboardHome);
  }

  void _onBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      // Back from step 1 → return to type selection
      setState(() => _accountType = null);
    }
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _companyNameCtrl.dispose();
    _employerIdCtrl.dispose();
    _jobTitleCtrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Show account type selection until a type is picked
    if (_accountType == null) {
      return _TypeSelectionScreen(
        onTypeSelected: (type) => setState(() => _accountType = type),
        onSignIn: () => context.pop(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              step: _step,
              totalSteps: _totalSteps,
              title: _stepTitle,
              accountType: _accountType!,
              onBack: _onBack,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepContent(),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _buttonLabel,
                    onPressed: () => _onNext(context),
                    icon: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 18),
                    gradientStart: _buttonLooksDisabled
                        ? AppColors.textTertiary
                        : null,
                    gradientEnd: _buttonLooksDisabled
                        ? AppColors.textTertiary
                        : null,
                  ),
                  if (_step == 1) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      case 6:
        return _isEmployer ? _buildStep7() : _buildStep6();
      case 7:
        return _buildStep6(); // employer only — password is last
      default:
        return const SizedBox();
    }
  }

  // ── Step builders ───────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldInput(
          label: 'Full Name',
          hint: 'Alex Johnson',
          controller: _nameCtrl,
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        InfoBanner(
          emoji: _isEmployer ? '🏢' : '👋',
          text: _isEmployer
              ? "Let's set up your employer account."
              : "Welcome! Let's get you set up safely.",
          color: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldInput(
          label: 'Mobile Number',
          hint: '+1 (555) 000-0000',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.call_outlined,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          emoji: '📱',
          text: "We'll send a 6-digit verification code to this number.",
          color: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _OtpStepIcon()),
        const SizedBox(height: 20),
        Text(
          'Mobile Verification',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          '6-digit code sent to ${_phoneCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 28),
        OtpInputWidget(
          length: 6,
          onCompleted: (_) {},
          onResend: () {},
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldInput(
          label: 'Email Address',
          hint: 'alex@example.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          emoji: '📧',
          text: "We'll send a 6-digit code to your email address.",
          color: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _OtpStepIcon()),
        const SizedBox(height: 20),
        Text(
          'Email Verification',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          '6-digit code sent to ${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 28),
        OtpInputWidget(
          length: 6,
          onCompleted: (_) {},
          onResend: () {},
        ),
      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldInput(
          label: 'Password',
          hint: 'Min. 8 characters',
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixWidget: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        SegmentedBar(
          segments: 4,
          filled: (_passwordStrength * 4).round(),
          filledColor: _strengthColor,
          unfilledColor: AppColors.border,
        ),
        if (_passwordCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _strengthLabel,
            style: GoogleFonts.inter(
                color: _strengthColor,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 16),
        const InfoBanner(
          emoji: '🔒',
          text: 'End-to-end encrypted. Never stored in plain text.',
          color: AppColors.success,
        ),
      ],
    );
  }

  // ── Employer-only step ───────────────────────────────────────────────────────
  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldInput(
          label: 'Company Name',
          hint: 'Acme Corporation',
          controller: _companyNameCtrl,
          prefixIcon: Icons.business_outlined,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FieldInput(
          label: 'Employer ID',
          hint: 'e.g. EMP-00123',
          controller: _employerIdCtrl,
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FieldInput(
          label: 'Job Title (Optional)',
          hint: 'e.g. HR Manager',
          controller: _jobTitleCtrl,
          prefixIcon: Icons.work_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          emoji: '🏢',
          text:
              'Your company details will appear on your employer profile visible to members.',
          color: AppColors.blue,
        ),
      ],
    );
  }
}

// ── Account Type Selection Screen ────────────────────────────────────────────

class _TypeSelectionScreen extends StatefulWidget {
  final ValueChanged<_AccountType> onTypeSelected;
  final VoidCallback onSignIn;

  const _TypeSelectionScreen({
    required this.onTypeSelected,
    required this.onSignIn,
  });

  @override
  State<_TypeSelectionScreen> createState() => _TypeSelectionScreenState();
}

class _TypeSelectionScreenState extends State<_TypeSelectionScreen> {
  _AccountType? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onSignIn,
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(height: 24),
                const AppLogoWidget(
                    size: LogoSize.sm, variant: LogoVariant.light),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'How will you be using SAFEE MEET?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Type cards ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TypeCard(
                    icon: Icons.person_rounded,
                    title: 'Normal User',
                    description:
                        'I\'m an individual looking to meet others safely and verify my identity.',
                    selected: _selected == _AccountType.normalUser,
                    onTap: () =>
                        setState(() => _selected = _AccountType.normalUser),
                  ),
                  const SizedBox(height: 16),
                  _TypeCard(
                    icon: Icons.business_rounded,
                    title: 'Employer / Business',
                    description:
                        'I represent a company and want to conduct verified, safe business meetings.',
                    selected: _selected == _AccountType.employer,
                    onTap: () =>
                        setState(() => _selected = _AccountType.employer),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Continue',
                    onPressed: _selected == null
                        ? null
                        : () => widget.onTypeSelected(_selected!),
                    icon: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 18),
                    gradientStart:
                        _selected == null ? AppColors.textTertiary : null,
                    gradientEnd:
                        _selected == null ? AppColors.textTertiary : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: widget.onSignIn,
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final _AccountType accountType;
  final VoidCallback onBack;

  const _Header({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.accountType,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const AppLogoWidget(
                  size: LogoSize.sm, variant: LogoVariant.light),
              const Spacer(),
              // Account type pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      accountType == _AccountType.employer
                          ? Icons.business_rounded
                          : Icons.person_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      accountType == _AccountType.employer
                          ? 'Employer'
                          : 'Normal User',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'STEP $step OF $totalSteps',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 16),
          SegmentedBar(
            segments: totalSteps,
            filled: step,
            filledColor: AppColors.primary,
            unfilledColor: Colors.white.withOpacity(0.15),
          ),
        ],
      ),
    );
  }
}

class _OtpStepIcon extends StatelessWidget {
  const _OtpStepIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(child: Text('🔐', style: TextStyle(fontSize: 28))),
    );
  }
}
