import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

class FieldInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Widget? suffixWidget;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final int? maxLines;

  const FieldInput({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.focusNode,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.suffixWidget,
    this.onChanged,
    this.errorText,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  Widget? get _trailWidget => suffixWidget ?? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.08 * 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                const SizedBox(width: 16),
                Icon(prefixIcon, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 12),
              ] else
                const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: textInputAction,
                  textCapitalization: textCapitalization,
                  maxLines: obscureText ? 1 : maxLines,
                  inputFormatters: inputFormatters,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              if (_trailWidget != null) ...[
                _trailWidget!,
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
