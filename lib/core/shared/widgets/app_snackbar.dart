import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

enum _SnackType { success, error, info }

/// A truly premium, custom Bottom-Toast that bypasses Flutter's rigid SnackBar.
/// It slides up from the bottom of the screen, uses real glassmorphism,
/// and doesn't get clipped by default material constraints.
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
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _BottomToast(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _BottomToast extends StatefulWidget {
  final String message;
  final String? title;
  final _SnackType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _BottomToast({
    required this.message,
    required this.title,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_BottomToast> createState() => _BottomToastState();
}

class _BottomToastState extends State<_BottomToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Slide up from below
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (widget.type) {
      _SnackType.success => (AppColors.success, Icons.check_circle_rounded),
      _SnackType.error => (AppColors.error, Icons.error_rounded),
      _SnackType.info => (AppColors.blue, Icons.info_rounded),
    };

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      bottom: keyboardHeight + bottomPadding + 24, // Always keep a healthy margin
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF121827), // Deep, sleek dark background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                // Deep black drop shadow for elevation
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                // Subtle colored ambient glow
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: widget.title == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: widget.title == null
                      ? Text(
                          widget.message,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.message,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) => widget.onDismiss());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
