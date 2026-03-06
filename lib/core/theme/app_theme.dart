import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --- Color Palette: "City Boy" Urban ---
  static const Color background   = Color(0xFF0D0D0D);
  static const Color surface      = Color(0xFF1A1A1A);
  static const Color surfaceAlt   = Color(0xFF242424);
  static const Color border       = Color(0xFF2E2E2E);
  static const Color textPrimary  = Color(0xFFF0EEE9);
  static const Color textSecondary = Color(0xFF888888);
  static const Color accent       = Color(0xFFE2FF4F); // Acid yellow — sporty/urban
  static const Color accentDim    = Color(0xFF8A9A2F);
  static const Color danger       = Color(0xFFFF4F4F);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        surfaceContainerHighest: surface,
        primary: accent,
        onPrimary: background,
        secondary: accentDim,
        onSecondary: background,
        onSurface: textPrimary,
        outline: border,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.0,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: background,
        elevation: 0,
        shape: CircleBorder(),
      ),
      dividerColor: border,
    );
  }
}
