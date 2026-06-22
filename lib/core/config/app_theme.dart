import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.primary,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        space: 1,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        surface: AppColors.darkBg2,
        onSurface: Colors.white,
        error: AppColors.primary,
      ),
      textTheme: _buildTextTheme(base.textTheme, dark: true),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, {bool dark = false}) {
    final color = dark ? Colors.white : AppColors.textPrimary;
    return base.copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w900, color: color),
      displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w800, color: color),
      displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: color),
      headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: color),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
    );
  }
}
