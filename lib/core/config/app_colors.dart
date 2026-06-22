import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF1F3D);
  static const Color primaryLight = Color(0xFFFF4D6D);

  // ── Dark Backgrounds ─────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkBg2 = Color(0xFF1E293B);
  static const Color darkBg3 = Color(0xFF2D2D2D);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color teal = Color(0xFF14B8A6);
  static const Color pink = Color(0xFFEC4899);

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFF1F5F9);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
    stops: [0.0, 1.0],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment(0.0, -0.8),
    end: Alignment(0.0, 1.0),
    colors: [darkBg, darkBg2],
  );

  static const LinearGradient darkGradient160 = LinearGradient(
    begin: Alignment(-0.5, -1.0),
    end: Alignment(0.5, 1.0),
    colors: [darkBg, darkBg2],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successLight],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, blueLight],
  );
}
