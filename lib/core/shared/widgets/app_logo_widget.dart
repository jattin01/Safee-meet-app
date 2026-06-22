import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import 'safee_shield_painter.dart';

enum LogoSize { sm, md, lg, xl }
enum LogoVariant { light, dark, gradient }

class AppLogoWidget extends StatelessWidget {
  final LogoSize size;
  final LogoVariant variant;

  const AppLogoWidget({
    super.key,
    this.size = LogoSize.md,
    this.variant = LogoVariant.dark,
  });

  double get _iconSize => switch (size) {
        LogoSize.sm => 32,
        LogoSize.md => 42,
        LogoSize.lg => 56,
        LogoSize.xl => 80,
      };

  double get _textSize => switch (size) {
        LogoSize.sm => 13,
        LogoSize.md => 17,
        LogoSize.lg => 22,
        LogoSize.xl => 30,
      };

  double get _tagSize => switch (size) {
        LogoSize.sm => 0,
        LogoSize.md => 0,
        LogoSize.lg => 9,
        LogoSize.xl => 11,
      };

  Color get _safeeColor => variant == LogoVariant.light ? Colors.white : const Color(0xFF111111);
  Color get _tagColor =>
      variant == LogoVariant.light ? Colors.white.withOpacity(0.65) : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeeMeetShieldIcon(size: _iconSize),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'SAFEE ',
                  style: GoogleFonts.inter(
                    fontSize: _textSize,
                    fontWeight: FontWeight.w900,
                    color: _safeeColor,
                    letterSpacing: 0.04 * _textSize,
                  ),
                ),
                Text(
                  'MEET',
                  style: GoogleFonts.inter(
                    fontSize: _textSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.04 * _textSize,
                  ),
                ),
              ],
            ),
            if (_tagSize > 0) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Are you verified?',
                    style: GoogleFonts.inter(
                      fontSize: _tagSize,
                      fontWeight: FontWeight.w500,
                      color: _tagColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 12,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
