import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool disabled;
  final Widget? icon;
  final Color? gradientStart;
  final Color? gradientEnd;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.icon,
    this.gradientStart,
    this.gradientEnd,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.disabled || widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: _isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            gradient: _isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.gradientStart ?? AppColors.primary,
                      widget.gradientEnd ?? AppColors.primaryLight,
                    ],
                  ),
            color: _isDisabled ? AppColors.textTertiary.withOpacity(0.4) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else ...[
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (widget.icon != null) ...[const SizedBox(width: 6), widget.icon!],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
