import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

class VerificationBadge extends StatelessWidget {
  final String? label;
  final Color? color;
  final String? level;

  const VerificationBadge({
    super.key,
    this.label,
    this.color,
    this.level,
  }) : assert(label != null || level != null,
            'Provide either label+color or level');

  String get _resolvedLabel {
    if (label != null) return label!;
    switch (level) {
      case 'level1':
        return 'Level 1 Verified';
      case 'level2':
        return 'Level 2 Verified';
      case 'professional':
        return 'Professional';
      default:
        return 'Unverified';
    }
  }

  Color get _resolvedColor {
    if (color != null) return color!;
    switch (level) {
      case 'level1':
        return AppColors.blue;
      case 'level2':
        return AppColors.success;
      case 'professional':
        return AppColors.purple;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _resolvedColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _resolvedLabel,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _resolvedColor,
        ),
      ),
    );
  }
}
