import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

enum _SnackType { success, error, info }

/// Consistent floating-snackbar look for validation/error/success feedback,
/// used across the auth flow (and anywhere else that wants the same style)
/// instead of ad hoc `ScaffoldMessenger` calls with one-off styling.
abstract final class AppSnackbar {
  static void success(BuildContext context, String message,
          {String? title, Duration duration = const Duration(seconds: 3)}) =>
      _show(context, message, _SnackType.success, duration, title);

  static void error(BuildContext context, String message,
          {String? title, Duration duration = const Duration(seconds: 3)}) =>
      _show(context, message, _SnackType.error, duration, title);

  static void info(BuildContext context, String message,
          {String? title, Duration duration = const Duration(seconds: 3)}) =>
      _show(context, message, _SnackType.info, duration, title);

  static void _show(BuildContext context, String message, _SnackType type,
      Duration duration, String? title) {
    final (color, icon) = switch (type) {
      _SnackType.success => (AppColors.success, Icons.check_circle_rounded),
      _SnackType.error => (AppColors.error, Icons.error_rounded),
      _SnackType.info => (AppColors.primary, Icons.info_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: title == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: title == null
                    ? Text(
                        message,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: duration,
        ),
      );
  }
}
