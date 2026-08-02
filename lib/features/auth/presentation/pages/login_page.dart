import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/app_logo_widget.dart';
import '../../../../core/shared/widgets/app_snackbar.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/otp_input_widget.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phoneCtrl   = TextEditingController();
  final _phoneFocus  = FocusNode();

  // ── Step ──────────────────────────────────────────────────────────────────
  bool _isOtpStep = false;

  // ── Firebase phone auth ───────────────────────────────────────────────────
  String? _verificationId;
  String? _enteredOtp;
  bool    _sendingOtp   = false;
  bool    _verifyingOtp = false;
  String? _otpError;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ── Phone validation ──────────────────────────────────────────────────────
  bool get _isValidPhone {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10;
  }

  // ── E.164 conversion ──────────────────────────────────────────────────────
  String _toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (raw.startsWith('+')) return raw.replaceAll(RegExp(r'\s'), '');
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    if (digits.length == 11 && digits.startsWith('0'))  return '+91${digits.substring(1)}';
    if (digits.length == 10) return '+91$digits';
    return '+$digits';
  }

  // ── Step 1: verify the number is registered before an OTP is ever sent ────
  void _onSendOtpPressed() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    context.read<AuthBloc>().add(PhoneRegistrationCheckRequested(_toE164(phone)));
  }

  // ── Firebase: Send OTP (only called once registration is confirmed) ──────
  Future<void> _sendPhoneOtp(String e164) async {
    setState(() { _sendingOtp = true; _otpError = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android auto-retrieval
        try {
          final result = await FirebaseAuth.instance.signInWithCredential(credential);
          final token  = await result.user?.getIdToken();
          if (token != null && mounted) {
            context.read<AuthBloc>().add(
              LoginRequested(provider: 'phone', providerToken: token),
            );
          }
        } catch (_) {}
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() {
            _sendingOtp = false;
            _otpError   = e.message ?? 'Phone verification failed.';
          });
        }
      },
      codeSent: (verificationId, _) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _sendingOtp     = false;
            _isOtpStep      = true;
          });
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── Firebase: Verify OTP → Backend Login ──────────────────────────────────
  Future<void> _verifyPhoneOtp() async {
    if (_verificationId == null || _enteredOtp == null) return;
    setState(() { _verifyingOtp = true; _otpError = null; });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode:        _enteredOtp!,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final token  = await result.user?.getIdToken();

      if (token != null && mounted) {
        setState(() => _verifyingOtp = false);
        context.read<AuthBloc>().add(
          LoginRequested(provider: 'phone', providerToken: token),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _verifyingOtp = false;
          _otpError = e.message ?? 'Invalid OTP. Please try again.';
        });
      }
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  void _onGoogleSignIn() {
    context.read<AuthBloc>().add(const GoogleLoginRequested());
  }

  void _onAppleSignIn() {
    context.read<AuthBloc>().add(const AppleLoginRequested());
  }

  // Apple only accepts native Sign in with Apple on iOS/macOS; Android/web
  // would need a separate Services ID + web redirect flow that isn't set up.
  bool get _supportsAppleSignIn =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  // ── USER_NOT_REGISTERED bottom sheet ──────────────────────────────────────
  void _showNotRegisteredSheet(BuildContext ctx, String message) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _NotRegisteredSheet(
        message: message,
        onRegister: () {
          Navigator.pop(sheetCtx);
          sheetCtx.push(AppRoutes.register);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          context.go(AppRoutes.dashboardHome);
        }
        if (state is PhoneRegistrationVerified) {
          _sendPhoneOtp(state.phone);
        }
        if (state is UserNotRegistered) {
          _showNotRegisteredSheet(context, state.message);
        }
        if (state is AuthFailureState) {
          AppSnackbar.error(context, state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: AppColors.lightBg,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(isOtpStep: _isOtpStep),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        24, 28, 24, context.bottomSafePadding(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isOtpStep)
                          ..._buildPhoneStep(context, isLoading)
                        else
                          ..._buildOtpStep(context, isLoading),
                        if (_otpError != null) ...[
                          const SizedBox(height: 12),
                          Text(_otpError!,
                              style: TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 28),
                        _Footer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Phone step ────────────────────────────────────────────────────────────
  List<Widget> _buildPhoneStep(BuildContext context, bool isLoading) {
    return [
      _PhoneInput(
        controller: _phoneCtrl,
        focusNode:  _phoneFocus,
        onChanged:  (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: _sendingOtp
            ? 'Sending OTP...'
            : (isLoading ? 'Checking number...' : 'Send OTP'),
        onPressed: (_sendingOtp || isLoading || !_isValidPhone)
            ? null
            : _onSendOtpPressed,
        gradientStart: (_sendingOtp || !_isValidPhone)
            ? AppColors.textTertiary : null,
        gradientEnd: (_sendingOtp || !_isValidPhone)
            ? AppColors.textTertiary : null,
      ),
      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or continue with',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
          child: _SocialButton(
            label: isLoading ? 'Signing in…' : 'Google',
            icon:  isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : SizedBox(
                    width: 20, height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
            onPressed: isLoading ? null : _onGoogleSignIn,
          ),
        ),
        if (_supportsAppleSignIn) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _SocialButton(
              label:     'Apple',
              icon:      const Icon(Icons.apple, color: Colors.black, size: 20),
              onPressed: isLoading ? null : _onAppleSignIn,
            ),
          ),
        ],
      ]),
    ];
  }

  // ── OTP step ──────────────────────────────────────────────────────────────
  List<Widget> _buildOtpStep(BuildContext context, bool isLoading) {
    return [
      const Center(child: _OtpStepIcon()),
      const SizedBox(height: 20),
      Text(
        'Enter OTP Code',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      ),
      const SizedBox(height: 6),
      Text(
        'Sent to ${_phoneCtrl.text.trim()}',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 28),
      OtpInputWidget(
        length: 6,
        // Auto-submits the moment all 6 digits are present (typed, pasted,
        // or filled by the OS's SMS/one-time-code autofill) — no separate
        // button tap needed. _verifyPhoneOtp itself is unchanged; this just
        // calls it automatically instead of waiting for a button press.
        onCompleted: (otp) {
          setState(() => _enteredOtp = otp);
          _verifyPhoneOtp();
        },
        onResend:    () => setState(() {
          _isOtpStep  = false;
          _enteredOtp = null;
          _otpError   = null;
        }),
      ),
      const SizedBox(height: 20),
      BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final loading = state is AuthLoading || _verifyingOtp;
          return PrimaryButton(
            label: loading ? 'Verifying...' : 'Verify & Sign In',
            onPressed: (loading || (_enteredOtp?.length ?? 0) < 6)
                ? null
                : _verifyPhoneOtp,
            gradientStart: (_enteredOtp?.length ?? 0) < 6
                ? AppColors.textTertiary : null,
            gradientEnd: (_enteredOtp?.length ?? 0) < 6
                ? AppColors.textTertiary : null,
          );
        },
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () => setState(() {
            _isOtpStep  = false;
            _enteredOtp = null;
            _otpError   = null;
          }),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Change number',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      ),
    ];
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NotRegisteredSheet extends StatelessWidget {
  final String message;
  final VoidCallback onRegister;
  const _NotRegisteredSheet({required this.message, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_add_alt_1_rounded,
                    color: AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Not Registered',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Register Now',
                    onPressed: onRegister,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isOtpStep;
  const _Header({required this.isOtpStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const AppLogoWidget(size: LogoSize.sm, variant: LogoVariant.light),
          const SizedBox(height: 28),
          Text(
            isOtpStep ? 'Verify your number' : 'Welcome back',
            style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            isOtpStep
                ? 'Enter the code we just sent you'
                : 'Sign in to your secure account',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

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

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('New to SAFEE MEET? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      GestureDetector(
        onTap: () => context.push(AppRoutes.register),
        child: Text('Create Account',
            style: TextStyle(
                color: AppColors.primary, fontSize: 14,
                fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

class _SocialButton extends StatelessWidget {
  final String      label;
  final Widget      icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label, required this.icon, this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon:      icon,
    label:     Text(label,
        style: GoogleFonts.inter(
            color: AppColors.textPrimary, fontSize: 14,
            fontWeight: FontWeight.w700)),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      side:  BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

// ── Phone Input with +91 prefix ───────────────────────────────────────────────
class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode?             focusNode;
  final ValueChanged<String>?  onChanged;

  const _PhoneInput({
    required this.controller,
    this.focusNode,
    this.onChanged,
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
            // Country code prefix
            Container(
              padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🇮🇳', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('+91',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ]),
            ),
            // Number input
            Expanded(
              child: TextField(
                controller:      controller,
                focusNode:       focusNode,
                onChanged:       onChanged,
                keyboardType:    TextInputType.phone,
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textPrimary),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
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
        Text('Enter 10-digit mobile number',
            style: TextStyle(
                color: AppColors.textTertiary, fontSize: 12)),
      ],
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect  = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.5708, 3.1416, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 0, 1.5708, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.5708, 1.5708, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.1416, 1.5708, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.32, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
