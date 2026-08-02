import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// A single real `TextField` (transparent, stacked over the visible boxes)
/// backs all the digits. This — rather than one `TextField` per box — is
/// what lets the OS's SMS/one-time-code autofill suggestion target the
/// field at all; autofill can't target a widget that doesn't exist.
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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _value = '';
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    // Auto-focus so the keyboard (and the OS's one-time-code suggestion,
    // where supported) appears the moment this step is shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits != raw) {
      _controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    setState(() => _value = digits);
    widget.onChanged?.call(digits);

    if (digits.length == widget.length) {
      if (!_completedFired) {
        _completedFired = true;
        HapticFeedback.lightImpact();
        _focusNode.unfocus();
        widget.onCompleted(digits);
      }
    } else {
      _completedFired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (i) {
                  final isFilled = i < _value.length;
                  final isActive =
                      i == _value.length && _focusNode.hasFocus;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppColors.primary.withOpacity(0.06)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFilled || isActive
                            ? AppColors.primary
                            : AppColors.border,
                        width: isFilled || isActive ? 2 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: isFilled
                        ? Text(
                            _value[i],
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : (isActive ? const _BlinkingCaret() : null),
                  );
                }),
              ),
              // Real input sits on top, fully transparent — it captures
              // taps/typing/autofill; the boxes above are pure display.
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: widget.length * 56.0,
                  height: 56,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: widget.length,
                    showCursor: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onChanged,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

/// A soft blinking caret marking the next box to be filled — replaces the
/// plain static border highlight with a small motion cue, matching the
/// blinking-cursor convention users expect from a native text field.
class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        width: 2,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
