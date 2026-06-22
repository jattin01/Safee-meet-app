import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

class OtpInputWidget extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final VoidCallback? onResend;
  final int length;
  final ValueChanged<String>? onChanged;

  const OtpInputWidget({
    super.key,
    required this.onCompleted,
    this.onResend,
    this.length = AppConstants.otpLength,
    this.onChanged,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      FocusScope.of(context).unfocus();
      _checkComplete();
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _checkComplete();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void _checkComplete() {
    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);
    if (otp.length == widget.length &&
        otp.split('').every((d) => RegExp(r'\d').hasMatch(d))) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: _controllers[i].text.isNotEmpty
                    ? AppColors.primary.withOpacity(0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _controllers[i].text.isNotEmpty
                      ? AppColors.primary
                      : AppColors.border,
                  width: _controllers[i].text.isNotEmpty ? 2 : 1.5,
                ),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (e) => _onKeyEvent(i, e),
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => _onChanged(i, v),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            );
          }),
        ),
        if (widget.onResend != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive it? ",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              GestureDetector(
                onTap: widget.onResend,
                child: Text(
                  'Resend OTP',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
