import 'package:country_code_picker/country_code_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/app_logo_widget.dart';
import '../../../../core/shared/widgets/app_snackbar.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/info_banner.dart';
import '../../../../core/shared/widgets/otp_input_widget.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../../../core/shared/widgets/segmented_bar.dart';
import '../../../auth/data/remote_data_sources/auth_remote_data_source.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

enum _AccountType { normalUser, employer }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ── Account type ────────────────────────────────────────────────────────────
  _AccountType? _accountType;

  // ── Step state ───────────────────────────────────────────────────────────────
  int _step = 1;

  // ── Form fields ──────────────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _companyNameCtrl = TextEditingController();

  // ── Phone OTP (backend-verified) state ────────────────────────────────────
  String? _firebaseIdToken;
  bool    _sendingOtp   = false;
  bool    _verifyingOtp = false;
  String? _otpError;
  String? _enteredOtp;

  // ── Email OTP state ───────────────────────────────────────────────────────
  bool    _sendingEmailOtp   = false;
  bool    _verifyingEmailOtp = false;
  String? _emailOtpError;
  String? _enteredEmailOtp;
  bool    _emailVerified = false;

  // ── Consent ───────────────────────────────────────────────────────────────
  bool _consentAccepted = false;

  // ── Step config ───────────────────────────────────────────────────────────
  bool get _isEmployer => _accountType == _AccountType.employer;
  // Normal:   1-Name 2-Phone 3-PhoneOTP 4-Email 5-Consent
  // Employer: 1-Name 2-Phone 3-PhoneOTP 4-Company 5-Email 6-Consent
  int  get _totalSteps => _isEmployer ? 6 : 5;

  String get _stepTitle {
    if (_isEmployer) {
      return const [
        'Your Name', 'Mobile Number', 'Verify Mobile',
        'Company Details', 'Email Address', 'Terms & Consent',
      ][_step - 1];
    }
    return const [
      'Your Name', 'Mobile Number', 'Verify Mobile',
      'Email Address', 'Terms & Consent',
    ][_step - 1];
  }

  // ── Button labels ─────────────────────────────────────────────────────────
  String get _buttonLabel {
    if (_step == 2) return _sendingOtp ? 'Sending...' : 'Send OTP';
    if (_step == 3) return _verifyingOtp ? 'Verifying...' : 'Verify';
    if (_step == _totalSteps) return 'Create Account';
    return 'Next';
  }

  bool get _buttonEnabled {
    final emailStep = _isEmployer ? 5 : 4;
    switch (_step) {
      case 1: return _nameCtrl.text.trim().isNotEmpty;
      case 2: return _phoneDigits.length >= 7 && _phoneDigits.length <= 15 && !_sendingOtp;
      case 3: return (_enteredOtp?.length ?? 0) == 6 && !_verifyingOtp;
      default:
        if (_step == 4 && _isEmployer) return _companyNameCtrl.text.trim().isNotEmpty;
        if (_step == emailStep) {
          final email = _emailCtrl.text.trim();
          return email.isNotEmpty && email.contains('@') && email.contains('.');
        }
        if (_step == _totalSteps) return _consentAccepted;
        return true;
    }
  }

  // ── Navigation & API calls ────────────────────────────────────────────────

  Future<void> _onNext(BuildContext context) async {
    if (_step == 2) { _sendPhoneOtp(); return; }
    if (_step == 3) { _verifyPhoneOtp(); return; }

    if (_step < _totalSteps) {
      setState(() => _step++);
      return;
    }
    _submitRegistration(context);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _phoneDigits => _phoneCtrl.text.replaceAll(RegExp(r'[^\d]'), '');

  // ── Country dial code (editable via the country selector) ────────────────
  String _dialCode = '91';

  String _toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (raw.startsWith('+')) return raw.replaceAll(RegExp(r'\s'), '');
    if (digits.startsWith(_dialCode) && digits.length > _dialCode.length) {
      return '+$digits';
    }
    if (digits.startsWith('0')) return '+$_dialCode${digits.substring(1)}';
    return '+$_dialCode$digits';
  }

  // ── Backend: Send OTP (registration-specific endpoint) ────────────────────
  void _sendPhoneOtp() {
    final e164 = _toE164(_phoneCtrl.text.trim());
    setState(() { _sendingOtp = true; _otpError = null; });
    context.read<AuthBloc>().add(SendRegisterOtpRequested(e164));
  }

  // ── Backend: Resend OTP — stays on the OTP step, never navigates away ────
  void _resendPhoneOtp() {
    setState(() { _enteredOtp = null; _otpError = null; });
    context.read<AuthBloc>().add(ResendOtpRequested(_toE164(_phoneCtrl.text.trim())));
  }

  // ── Backend: Verify OTP → Firebase custom-token session ───────────────────
  void _verifyPhoneOtp() {
    if (_enteredOtp == null) return;
    setState(() { _verifyingOtp = true; _otpError = null; });
    context.read<AuthBloc>().add(OtpVerificationRequested(
      phone: _toE164(_phoneCtrl.text.trim()),
      otp:   _enteredOtp!,
    ));
  }

  // ── Backend: Send Email OTP ───────────────────────────────────────────────
  Future<void> _sendEmailOtp(BuildContext context) async {
    final email = _emailCtrl.text.trim();
    setState(() { _sendingEmailOtp = true; _emailOtpError = null; });

    try {
      final ds = GetIt.I<AuthRemoteDataSource>() as AuthRemoteDataSourceImpl;
      final devOtp = await ds.sendEmailOtpWithDevCode(email);

      if (mounted) {
        setState(() { _sendingEmailOtp = false; _step++; });
        if (devOtp != null) {
          AppSnackbar.info(context, '[DEV] Email OTP: $devOtp',
              duration: const Duration(seconds: 10));
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _sendingEmailOtp = false;
          _emailOtpError   = e.response?.data?['message'] ?? 'Failed to send OTP.';
        });
      }
    }
  }

  // ── Backend: Verify Email OTP ─────────────────────────────────────────────
  Future<void> _verifyEmailOtp(BuildContext context) async {
    if (_enteredEmailOtp == null) return;
    setState(() { _verifyingEmailOtp = true; _emailOtpError = null; });

    try {
      final ds = GetIt.I<AuthRemoteDataSource>() as AuthRemoteDataSourceImpl;
      await ds.verifyEmailOtp(_emailCtrl.text.trim(), _enteredEmailOtp!);
      if (mounted) {
        setState(() {
          _emailVerified    = true;
          _verifyingEmailOtp = false;
          _step++;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _verifyingEmailOtp = false;
          _emailOtpError     = e.response?.data?['message'] ?? 'Invalid OTP.';
        });
      }
    }
  }

  // ── Backend: Register ─────────────────────────────────────────────────────
  void _submitRegistration(BuildContext context) {
    if (_firebaseIdToken == null) {
      AppSnackbar.error(context, 'Phone verification required.');
      return;
    }

    context.read<AuthBloc>().add(RegisterRequested(
      provider:        'phone',
      providerToken:   _firebaseIdToken!,
      name:            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      email:           _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone:           _toE164(_phoneCtrl.text.trim()),
      accountType:     _isEmployer ? 'employer' : 'normal',
      companyName:     _isEmployer ? _companyNameCtrl.text.trim() : null,
      consentAccepted: _consentAccepted,
    ));
  }

  void _onBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      setState(() => _accountType = null);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _companyNameCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_accountType == null) {
      return _TypeSelectionScreen(
        onTypeSelected: (type) => setState(() => _accountType = type),
        onSignIn: () => context.pop(),
      );
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RegistrationSuccess) {
          context.go(AppRoutes.dashboardHome);
        } else if (state is OtpSent) {
          setState(() { _sendingOtp = false; _step = 3; });
        } else if (state is OtpResent) {
          AppSnackbar.success(context, 'OTP resent successfully.');
        } else if (state is PhoneOtpVerified) {
          setState(() {
            _firebaseIdToken = state.firebaseIdToken;
            _verifyingOtp    = false;
            _step            = 4;
          });
        } else if (state is UserNotRegistered) {
          // Shouldn't happen on register, but handle gracefully
          AppSnackbar.error(context, state.message);
        } else if (state is AuthFailureState) {
          setState(() { _sendingOtp = false; _verifyingOtp = false; });
          AppSnackbar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                step:        _step,
                totalSteps:  _totalSteps,
                title:       _stepTitle,
                accountType: _accountType!,
                onBack:      _onBack,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 28, 24, context.bottomSafePadding(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepContent(),
                    if (_otpError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _otpError!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 28),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return PrimaryButton(
                          label:     isLoading ? 'Please wait...' : _buttonLabel,
                          onPressed: (isLoading || !_buttonEnabled)
                              ? null
                              : () => _onNext(context),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                          gradientStart: (!_buttonEnabled || isLoading)
                              ? AppColors.textTertiary : null,
                          gradientEnd: (!_buttonEnabled || isLoading)
                              ? AppColors.textTertiary : null,
                        );
                      },
                    ),
                    if (_step == 1) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14)),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text('Sign In',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                )),
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
      ),
    );
  }

  Widget _buildStepContent() {
    // Normal:   1-Name 2-Phone 3-PhoneOTP 4-Email 5-Consent
    // Employer: 1-Name 2-Phone 3-PhoneOTP 4-Company 5-Email 6-Consent
    if (_isEmployer) {
      switch (_step) {
        case 1: return _buildNameStep();
        case 2: return _buildPhoneStep();
        case 3: return _buildPhoneOtpStep();
        case 4: return _buildCompanyStep();
        case 5: return _buildEmailStep();
        case 6: return _buildConsentStep();
      }
    } else {
      switch (_step) {
        case 1: return _buildNameStep();
        case 2: return _buildPhoneStep();
        case 3: return _buildPhoneOtpStep();
        case 4: return _buildEmailStep();
        case 5: return _buildConsentStep();
      }
    }
    return const SizedBox();
  }

  // ── Step 1: Name ──────────────────────────────────────────────────────────
  Widget _buildNameStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldInput(
        label:               'Full Name',
        hint:                'Alex Johnson',
        controller:          _nameCtrl,
        prefixIcon:          Icons.person_outline,
        textCapitalization:  TextCapitalization.words,
        onChanged:           (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      InfoBanner(
        emoji: _isEmployer ? '🏢' : '👋',
        text:  _isEmployer
            ? "Let's set up your employer account."
            : "Welcome! Let's get you set up safely.",
        color: AppColors.blue,
      ),
    ],
  );

  // ── Step 2: Phone ─────────────────────────────────────────────────────────
  Widget _buildPhoneStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _PhoneInputField(
        controller: _phoneCtrl,
        onChanged:  (_) => setState(() {}),
        onCountryChanged: (country) =>
            setState(() => _dialCode = country.dialCode?.replaceAll('+', '') ?? '91'),
      ),
      const SizedBox(height: 16),
      const InfoBanner(
        emoji: '📱',
        text:  "We'll send a 6-digit OTP to verify this number.",
        color: AppColors.blue,
      ),
    ],
  );

  // ── Step 3: Phone OTP ─────────────────────────────────────────────────────
  Widget _buildPhoneOtpStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: _OtpStepIcon()),
      const SizedBox(height: 20),
      Text(
        'Mobile Verification',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      ),
      const SizedBox(height: 6),
      Text(
        'Enter the 6-digit code sent to ${_phoneCtrl.text.trim()}',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 28),
      OtpInputWidget(
        length: 6,
        onCompleted: (otp) => setState(() => _enteredOtp = otp),
        onResend: _resendPhoneOtp,
      ),
    ],
  );

  // ── Email OTP step ────────────────────────────────────────────────────────
  Widget _buildEmailOtpStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: _OtpStepIcon()),
      const SizedBox(height: 20),
      Text(
        'Email Verification',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      ),
      const SizedBox(height: 6),
      Text(
        'Enter the 6-digit code sent to ${_emailCtrl.text.trim()}',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 28),
      OtpInputWidget(
        length: 6,
        onCompleted: (otp) => setState(() => _enteredEmailOtp = otp),
        onResend: () {
          final emailStep = _isEmployer ? 5 : 4;
          setState(() { _step = emailStep; _enteredEmailOtp = null; });
        },
      ),
      if (_emailOtpError != null) ...[
        const SizedBox(height: 12),
        Text(_emailOtpError!,
            style: TextStyle(color: AppColors.error, fontSize: 13)),
      ],
    ],
  );

  // ── Step: Email ───────────────────────────────────────────────────────────
  Widget _buildEmailStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldInput(
        label:           'Email Address',
        hint:            'alex@example.com',
        controller:      _emailCtrl,
        keyboardType:    TextInputType.emailAddress,
        prefixIcon:      Icons.email_outlined,
        onChanged:       (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      const InfoBanner(
        emoji: '📧',
        text:  'Optional — used for account recovery and notifications.',
        color: AppColors.blue,
      ),
    ],
  );

  // ── Step: Company Details (employer only) ─────────────────────────────────
  Widget _buildCompanyStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldInput(
        label:              'Company Name',
        hint:               'Acme Corporation',
        controller:         _companyNameCtrl,
        prefixIcon:         Icons.business_outlined,
        textCapitalization: TextCapitalization.words,
        onChanged:          (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      const InfoBanner(
        emoji: '🏢',
        text:  'Company details appear on your employer profile visible to members.',
        color: AppColors.blue,
      ),
    ],
  );

  // ── Step: Consent ─────────────────────────────────────────────────────────
  Widget _buildConsentStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding:      const EdgeInsets.all(20),
        decoration:   BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Almost there!',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Please review and accept our terms before creating your account.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            _ConsentItem(icon: Icons.verified_user_outlined,  text: 'Identity verification powered by Firebase'),
            _ConsentItem(icon: Icons.lock_outline,            text: 'Your data is encrypted end-to-end'),
            _ConsentItem(icon: Icons.visibility_off_outlined, text: 'We never share your info with third parties'),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _consentAccepted = !_consentAccepted),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color:        _consentAccepted ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border:       Border.all(
                        color: _consentAccepted ? AppColors.primary : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: _consentAccepted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        children: [
                          const TextSpan(text: 'I agree to the SAFEE MEET '),
                          TextSpan(
                            text:  'Terms of Service',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text:  'Privacy Policy',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (_firebaseIdToken != null)
        InfoBanner(
          emoji: '✅',
          text:  'Phone verified.',
          color: AppColors.success,
        ),
      if (_emailVerified) ...[
        const SizedBox(height: 8),
        InfoBanner(
          emoji: '✅',
          text:  'Email verified.',
          color: AppColors.success,
        ),
      ],
    ],
  );
}

// ── Consent item ──────────────────────────────────────────────────────────────
class _ConsentItem extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _ConsentItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    ]),
  );
}

// ── Account Type Selection ─────────────────────────────────────────────────────
class _TypeSelectionScreen extends StatefulWidget {
  final ValueChanged<_AccountType> onTypeSelected;
  final VoidCallback               onSignIn;
  const _TypeSelectionScreen({required this.onTypeSelected, required this.onSignIn});

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
          Container(
            decoration: const BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(28),
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
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 24),
                const AppLogoWidget(size: LogoSize.sm, variant: LogoVariant.light),
                const SizedBox(height: 20),
                Text('Create Account',
                    style: GoogleFonts.inter(
                        fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Text('How will you be using SAFEE MEET?',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 32, 24, context.bottomSafePadding(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TypeCard(
                    icon:        Icons.person_rounded,
                    title:       'Normal User',
                    description: "I'm an individual looking to meet others safely and verify my identity.",
                    selected:    _selected == _AccountType.normalUser,
                    onTap:       () => setState(() => _selected = _AccountType.normalUser),
                  ),
                  const SizedBox(height: 16),
                  _TypeCard(
                    icon:        Icons.business_rounded,
                    title:       'Employer / Business',
                    description: "I represent a company and want to conduct verified, safe business meetings.",
                    selected:    _selected == _AccountType.employer,
                    onTap:       () => setState(() => _selected = _AccountType.employer),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label:        'Continue',
                    onPressed:    _selected == null
                        ? null
                        : () => widget.onTypeSelected(_selected!),
                    icon:         const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    gradientStart: _selected == null ? AppColors.textTertiary : null,
                    gradientEnd:   _selected == null ? AppColors.textTertiary : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: widget.onSignIn,
                        child: Text('Sign In',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 14,
                                fontWeight: FontWeight.w700)),
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

// ── Type Card ──────────────────────────────────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final IconData   icon;
  final String     title;
  final String     description;
  final bool       selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon, required this.title,
    required this.description, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding:  const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:         selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
        borderRadius:  BorderRadius.circular(20),
        border:        Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1.5,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color:        selected ? AppColors.primary : AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon,
              color: selected ? Colors.white : AppColors.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(description,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
        )),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  selected ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.textTertiary, width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 13)
              : null,
        ),
      ]),
    ),
  );
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int          step;
  final int          totalSteps;
  final String       title;
  final _AccountType accountType;
  final VoidCallback onBack;

  const _Header({
    required this.step, required this.totalSteps, required this.title,
    required this.accountType, required this.onBack,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkBg,
      borderRadius: BorderRadius.only(
        bottomLeft:  Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
    ),
    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const AppLogoWidget(size: LogoSize.sm, variant: LogoVariant.light),
          const Spacer(),
          Container(
            padding:    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                accountType == _AccountType.employer
                    ? Icons.business_rounded : Icons.person_rounded,
                color: Colors.white70, size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                accountType == _AccountType.employer ? 'Employer' : 'Normal User',
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        Text('STEP $step OF $totalSteps',
            style: GoogleFonts.inter(
                color: AppColors.textTertiary, fontSize: 12,
                fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 16),
        SegmentedBar(
          segments:      totalSteps,
          filled:        step,
          filledColor:   AppColors.primary,
          unfilledColor: Colors.white.withOpacity(0.15),
        ),
      ],
    ),
  );
}

// ── OTP icon ──────────────────────────────────────────────────────────────────
class _OtpStepIcon extends StatelessWidget {
  const _OtpStepIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 64, height: 64,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryLight],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 8),
        ),
      ],
    ),
    child: const Center(child: Text('🔐', style: TextStyle(fontSize: 28))),
  );
}

// ── Reusable phone input with +91 country code prefix ────────────────────────
class _PhoneInputField extends StatelessWidget {
  final TextEditingController      controller;
  final ValueChanged<String>?      onChanged;
  final ValueChanged<CountryCode>? onCountryChanged;

  const _PhoneInputField({
    required this.controller,
    this.onChanged,
    this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile Number',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(children: [
            // Country code selector (tap to change country)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(color: AppColors.border, width: 1.5)),
              ),
              child: CountryCodePicker(
                onChanged:       onCountryChanged,
                initialSelection: 'IN',
                favorite:        const ['+91', 'IN'],
                showFlag:        true,
                showDropDownButton: true,
                padding:         const EdgeInsets.symmetric(horizontal: 10),
                flagWidth:       22,
                textStyle: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                dialogTextStyle: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textPrimary),
                searchStyle: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textPrimary),
                // Package default is a bare, unstyled InputDecoration — no
                // hint, no icon, no border — which renders as an empty box
                // users can't tell is a search field. Give it a real look.
                searchDecoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textTertiary),
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.textTertiary, size: 20),
                  filled:         true,
                  fillColor:      AppColors.lightBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller:      controller,
                onChanged:       onChanged,
                keyboardType:    TextInputType.phone,
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textPrimary),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: InputDecoration(
                  hintText: '98765 43210',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text('Enter your mobile number without the country code',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ],
    );
  }
}
