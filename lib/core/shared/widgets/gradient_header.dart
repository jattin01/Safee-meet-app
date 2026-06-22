import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

/// Dark-gradient header used on secondary screens.
/// Use [title] + optional [subtitle] for a standard header with back button.
/// Use [child] for fully custom content.
class GradientHeader extends StatelessWidget {
  final Widget? child;
  final String? title;
  final String? subtitle;
  final double bottomRadius;
  final EdgeInsetsGeometry padding;
  final bool showBackButton;

  const GradientHeader({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.bottomRadius = 24,
    this.padding = const EdgeInsets.fromLTRB(20, 56, 20, 24),
    this.showBackButton = true,
  }) : assert(child != null || title != null,
            'Provide either child or title');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1.0),
          end: Alignment(0.4, 1.0),
          colors: [AppColors.darkBg, AppColors.darkBg2],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
      ),
      child: child ?? _DefaultContent(
        title: title!,
        subtitle: subtitle,
        showBackButton: showBackButton,
      ),
    );
  }
}

class _DefaultContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;

  const _DefaultContent({
    required this.title,
    this.subtitle,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBackButton) ...[
          GradientBackButton(onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 20),
        ],
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class GradientBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GradientBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: Colors.white),
      ),
    );
  }
}
