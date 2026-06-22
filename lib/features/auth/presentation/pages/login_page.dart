import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/app_logo_widget.dart';
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
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _isOtpStep = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    context.read<AuthBloc>().add(SendOtpRequested(phone));
  }

  void _verifyOtp(String otp) {
    final phone = _phoneCtrl.text.trim();
    context.read<AuthBloc>().add(
          OtpVerificationRequested(phone: phone, otp: otp),
        );
  }

  void _onGoogleSignIn() {
    context.read<AuthBloc>().add(const GoogleSignInStarted());
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpSent) {
          setState(() => _isOtpStep = true);
        }
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboardHome);
        }
        if (state is AuthError) {
          _showError(context, state.message);
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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isOtpStep)
                          ..._buildPhoneStep(context, isLoading)
                        else
                          ..._buildOtpStep(context, isLoading),
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

  List<Widget> _buildPhoneStep(BuildContext context, bool isLoading) {
    return [
      FieldInput(
        label: 'Mobile Number',
        hint: '+1 (555) 000-0000',
        controller: _phoneCtrl,
        focusNode: _phoneFocus,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.call_outlined,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))
        ],
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: isLoading ? 'Sending…' : 'Send OTP',
        onPressed: isLoading ? null : _sendOtp,
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'or continue with',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _SocialButton(
              label: isLoading ? 'Signing in…' : 'Google',
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomPaint(painter: _GoogleLogoPainter()),
                    ),
              onPressed: isLoading ? null : _onGoogleSignIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SocialButton(
              label: 'Apple',
              icon: const Icon(Icons.apple, color: Colors.black, size: 20),
              // Apple Sign-In — Phase 2
              onPressed: isLoading ? null : () {},
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildOtpStep(BuildContext context, bool isLoading) {
    final phone = _phoneCtrl.text.trim();
    return [
      const Center(child: _OtpStepIcon()),
      const SizedBox(height: 20),
      Text(
        'Enter OTP Code',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Sent to $phone',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 28),
      OtpInputWidget(
        length: 6,
        onCompleted: (otp) => _verifyOtp(otp),
        onResend: _sendOtp,
      ),
      const SizedBox(height: 24),
      PrimaryButton(
        label: isLoading ? 'Verifying…' : 'Verify',
        onPressed: isLoading ? null : () {},
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: isLoading ? null : () => setState(() => _isOtpStep = false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Go back',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
          bottomLeft: Radius.circular(28),
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
            'Welcome back',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to your secure account',
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

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to SAFEE MEET? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.register),
          child: Text(
            'Create Account',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
