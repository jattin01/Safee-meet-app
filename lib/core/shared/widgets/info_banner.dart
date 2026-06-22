import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Small tinted notice box used on auth screens, e.g.
/// "👋 Welcome! Let's get you set up safely."
class InfoBanner extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;

  const InfoBanner({
    super.key,
    required this.emoji,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
