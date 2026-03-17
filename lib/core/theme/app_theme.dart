import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --- Color Palette: "City Boy" Urban ---
  static const Color background    = Color(0xFF0D0D0D);
  static const Color surface       = Color(0xFF1A1A1A);
  static const Color surfaceAlt    = Color(0xFF242424);
  static const Color border        = Color(0xFF2E2E2E);
  static const Color textPrimary   = Color(0xFFF0EEE9);
  static const Color textSecondary = Color(0xFF888888);
  static const Color accent        = Color(0xFFE2FF4F); // Acid yellow — sporty/urban
  static const Color accentDim     = Color(0xFF8A9A2F);
  static const Color danger        = Color(0xFFFF4F4F);

  // ── Locale-aware title style ────────────────────────────────────────────────
  //
  // Used for brand titles and primary headings. Acid yellow, monospace,
  // with a solid underline decoration (zero border-radius).
  //
  //   Japanese — system monospace (covers CJK glyphs), 26 px, w700
  //   English  — Roboto Mono, 24 px, w700
  static TextStyle appTitleTheme(Locale locale) {
    const decoration = TextDecoration.underline;
    const decorationColor = accent;
    const decorationStyle = TextDecorationStyle.solid;

    if (locale.languageCode == 'ja') {
      return GoogleFonts.notoSansJp(
        fontWeight: FontWeight.w900,
        fontSize: 26,
        color: accent,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
      ).copyWith(
        // Belt-and-suspenders: if NotoSansJP hasn't loaded yet, fall through
        // to Hiragino Sans (iOS) which does ship bold CJK weights.
        fontFamilyFallback: ['Hiragino Sans', 'Noto Sans CJK JP', 'monospace'],
      );
    }

    return GoogleFonts.robotoMono(
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: accent,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }

  // ── Locale-aware content heading style ─────────────────────────────────────
  //
  // Used for user-generated note titles. RubikMonoOne covers Latin only —
  // Japanese text silently falls back to the system font at regular weight.
  // NotoSansJP ships distinct w900 CJK glyphs and is downloaded at runtime
  // by the google_fonts package; Hiragino Sans is the iOS belt-and-suspenders.
  static TextStyle contentTitleStyle(
    Locale locale, {
    double fontSize = 14,
    Color color = textPrimary,
    double letterSpacing = 1.0,
  }) {
    if (locale.languageCode == 'ja') {
      return GoogleFonts.notoSansJp(
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
      ).copyWith(
        fontFamilyFallback: ['Hiragino Sans', 'Noto Sans CJK JP'],
      );
    }
    return GoogleFonts.rubikMonoOne(
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // ── Locale-aware body text theme ────────────────────────────────────────────
  //
  // Consistent monospace styling for body and technical data across both
  // locales, with a slightly larger base size for Japanese to maintain
  // visual volume (CJK glyphs render denser than Latin at the same size).
  //
  //   Japanese — system monospace, base 16 px
  //   English  — Roboto Mono, base 14 px
  static TextTheme appTextTheme(Locale locale) {
    final isJa = locale.languageCode == 'ja';
    final bodySize = isJa ? 16.0 : 14.0;

    TextStyle _mono(
      double size,
      FontWeight weight,
      Color color, {
      double? letterSpacing,
    }) {
      if (isJa) {
        return GoogleFonts.notoSansJp(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: letterSpacing,
        );
      }
      return GoogleFonts.robotoMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return TextTheme(
      displayLarge: _mono(32, FontWeight.w800, textPrimary, letterSpacing: -1.0),
      titleLarge:   _mono(20, FontWeight.w700, textPrimary, letterSpacing: -0.5),
      titleMedium:  _mono(bodySize, FontWeight.w600, textPrimary),
      bodyMedium:   _mono(bodySize, FontWeight.w400, textSecondary),
      labelSmall:   _mono(11, FontWeight.w600, textSecondary, letterSpacing: 0.8),
    );
  }

  // ── Full locale-aware dark theme ────────────────────────────────────────────

  static ThemeData darkForLocale(Locale locale) {
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
      textTheme: appTextTheme(locale),
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

  // ── Static fallback (English) ───────────────────────────────────────────────
  static ThemeData get dark => darkForLocale(const Locale('en'));
}
