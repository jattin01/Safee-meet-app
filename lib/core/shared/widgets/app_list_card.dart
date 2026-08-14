import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../config/app_dimensions.dart';

/// Shared white, rounded, bordered card that lays out [children] with a
/// thin divider between each row — used for settings sections, info
/// panels, etc. Optionally renders an uppercase [header] caption inside the
/// card instead of a divider before the first row.
///
/// Consolidates the near-identical card markup that used to be
/// copy-pasted as a private `_Card` class in every screen.
class AppListCard extends StatelessWidget {
  final List<Widget> children;
  final String? header;

  const AppListCard({super.key, required this.children, this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: header != null ? const EdgeInsets.fromLTRB(16, 14, 16, 6) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Text(
              header!,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm - 2),
          ],
          ...List.generate(children.length, (i) {
            return Column(
              children: [
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    color: AppColors.borderLight,
                    indent: header != null ? 0 : 16,
                    endIndent: header != null ? 0 : 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
