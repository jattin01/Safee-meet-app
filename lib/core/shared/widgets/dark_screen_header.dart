import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../config/app_dimensions.dart';
import '../../routes/app_routes.dart';

/// Shared dark, rounded-bottom-corner header used at the top of secondary
/// (non-tab) and tab-root screens — back button + title (+ optional
/// trailing widget), with an optional [child] slot for extra content
/// (badges, summary cards, tabs, toggles, …) rendered below the title row.
///
/// Consolidates the near-identical header markup that used to be
/// copy-pasted as a private `_Header` class in every screen.
class DarkScreenHeader extends StatelessWidget {
  final String? title;
  final bool centerTitle;
  final double titleFontSize;
  final Widget? trailing;
  final Widget? child;
  final double childGap;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry? padding;

  const DarkScreenHeader({
    super.key,
    this.title,
    this.centerTitle = false,
    this.titleFontSize = 20,
    this.trailing,
    this.child,
    this.childGap = AppSpacing.xl - 2,
    this.onBack,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.header),
          bottomRight: Radius.circular(AppRadius.header),
        ),
      ),
      padding: padding ??
          EdgeInsets.fromLTRB(
            AppSpacing.xl,
            MediaQuery.of(context).padding.top + AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackButton(onTap: onBack),
              if (title != null) ...[
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Text(
                    title!,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              // Mirror the leading gap on the trailing side too when the
              // title is centered, so it stays visually centered between
              // the back button and the trailing widget.
              if (trailing != null) ...[
                if (centerTitle) const SizedBox(width: AppSpacing.md + 2),
                trailing!,
              ],
            ],
          ),
          if (child != null) ...[
            SizedBox(height: childGap),
            child!,
          ],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Several screens that use this header are also bottom-nav tabs, so
      // there may be nothing to pop (e.g. reached directly via the tab
      // bar) — fall back to Home in that case.
      onTap: onTap ?? () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }
}
