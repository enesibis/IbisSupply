import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// IbisSupply Design System — v3 (white-focused, premium restraint)
///
/// Zemin: #FFFFFF  Mürekkep: #0A0A0B
/// Aksan: İndigo #3F3FE8
/// Tipografi: Fraunces (display) · Inter (UI) · JetBrains Mono (teknik)
/// Geometri: 8px input · 10px button · 12px card · 16px hero · 999 pill
class AppTheme {
  // ── Renk sabitleri ────────────────────────────────────────────────────────
  static const Color ink     = Color(0xFF0A0A0B);
  static const Color bg      = Color(0xFFFFFFFF);
  static const Color night   = Color(0xFF0A0A0B);
  static const Color accent  = Color(0xFF3F3FE8);  // deep indigo
  static const Color purple  = Color(0xFF7B61FF);
  static const Color amber   = Color(0xFFB45309);
  static const Color error   = Color(0xFFB91C1C);

  static const Color riskLow      = Color(0xFF0F7A4B);  // success green
  static const Color riskMedium   = Color(0xFFB45309);  // warning amber
  static const Color riskHigh     = Color(0xFFB91C1C);  // danger red
  static const Color riskCritical = Color(0xFF7A0D0D);  // deep red

  // ── Tipografi yardımcıları ────────────────────────────────────────────────

  /// Başlık — Fraunces (display serif)
  static TextStyle heading({
    double fontSize = 24,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacingEm = -0.02,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? ink,
        height: height,
        letterSpacing: fontSize * letterSpacingEm,
        fontStyle: style,
      );

  /// UI metin — Inter regular
  static TextStyle sans({
    double fontSize = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? ink,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Geriye dönük uyumluluk — serif() artık Fraunces döner
  static TextStyle serif({
    double fontSize = 24,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = -0.48,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? ink,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: style,
      );

  /// Hash / ID / teknik veri — JetBrains Mono
  static TextStyle mono({
    double fontSize = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0.3,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final interText = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEEEEFE),
        onPrimaryContainer: Color(0xFF1A1A8C),
        secondary: purple,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: ink,
        surfaceContainerHighest: Color(0xFFFAFAFA),
        error: error,
        onError: Colors.white,
        outline: Color(0xFFE4E4E7),
      ),
      scaffoldBackgroundColor: bg,
      textTheme: interText.copyWith(
        displayLarge: GoogleFonts.fraunces(
            fontSize: 48, fontWeight: FontWeight.w400, color: ink,
            height: 1.15, letterSpacing: -0.96),
        displayMedium: GoogleFonts.fraunces(
            fontSize: 36, fontWeight: FontWeight.w400, color: ink,
            height: 1.2, letterSpacing: -0.72),
        displaySmall: GoogleFonts.fraunces(
            fontSize: 28, fontWeight: FontWeight.w400, color: ink,
            height: 1.25, letterSpacing: -0.56),
        headlineLarge: GoogleFonts.fraunces(
            fontSize: 24, fontWeight: FontWeight.w400, color: ink,
            height: 1.3, letterSpacing: -0.24),
        headlineMedium: GoogleFonts.fraunces(
            fontSize: 20, fontWeight: FontWeight.w400, color: ink,
            height: 1.3, letterSpacing: -0.2),
        headlineSmall: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600, color: ink,
            letterSpacing: -0.34),
        titleLarge: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, color: ink,
            letterSpacing: -0.15),
        titleMedium: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: ink),
        titleSmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: const Color(0xFF52525B)),
        bodyLarge: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w400, color: ink, height: 1.55),
        bodyMedium: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400, color: ink, height: 1.5),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: const Color(0xFFA1A1AA), height: 1.45),
        labelLarge: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: ink),
        labelMedium: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: const Color(0xFF52525B)),
        labelSmall: GoogleFonts.jetBrainsMono(
            fontSize: 11, fontWeight: FontWeight.w400,
            color: const Color(0xFFA1A1AA), letterSpacing: 1.32),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: ink, fontSize: 17, fontWeight: FontWeight.w600,
          letterSpacing: -0.34,
        ),
        iconTheme: const IconThemeData(color: ink, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE4E4E7),
          disabledForegroundColor: const Color(0xFFA1A1AA),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
          elevation: 0,
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
            color: const Color(0xFFA1A1AA), fontSize: 14),
        hintStyle: GoogleFonts.inter(
            color: const Color(0xFFD4D4D8), fontSize: 14),
        errorStyle: GoogleFonts.inter(color: error, fontSize: 11),
        prefixIconColor: const Color(0xFFA1A1AA),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: ink, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: const Color(0xFF52525B), fontSize: 13, height: 1.55,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle:
            GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF4F4F5),
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: ink),
        side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF4F4F5),
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: ink),
        subtitleTextStyle: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFFA1A1AA)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFA1A1AA),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent
              : const Color(0xFFE4E4E7),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Color(0xFFE4E4E7), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: Color(0xFFE4E4E7),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final interText = GoogleFonts.interTextTheme(base.textTheme);
    const darkInk    = Color(0xFFFFFFFF);
    const darkBg     = Color(0xFF08091A);
    const darkSurf   = Color(0xFF0F1128);
    const darkBorder = Color(0x1EFFFFFF);

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1F1F5C),
        onPrimaryContainer: Color(0xFFCCCCFD),
        secondary: purple,
        onSecondary: Colors.white,
        surface: darkSurf,
        onSurface: darkInk,
        surfaceContainerHighest: Color(0xFF161933),
        error: error,
        onError: Colors.white,
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: interText.copyWith(
        displayLarge: GoogleFonts.fraunces(
            fontSize: 48, fontWeight: FontWeight.w400, color: darkInk,
            height: 1.15, letterSpacing: -0.96),
        displayMedium: GoogleFonts.fraunces(
            fontSize: 36, fontWeight: FontWeight.w400, color: darkInk,
            height: 1.2, letterSpacing: -0.72),
        displaySmall: GoogleFonts.fraunces(
            fontSize: 28, fontWeight: FontWeight.w400, color: darkInk,
            height: 1.25, letterSpacing: -0.56),
        headlineLarge: GoogleFonts.fraunces(
            fontSize: 24, fontWeight: FontWeight.w400, color: darkInk,
            height: 1.3, letterSpacing: -0.24),
        headlineMedium: GoogleFonts.fraunces(
            fontSize: 20, fontWeight: FontWeight.w400, color: darkInk,
            height: 1.3, letterSpacing: -0.2),
        headlineSmall: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600, color: darkInk,
            letterSpacing: -0.34),
        titleLarge: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, color: darkInk,
            letterSpacing: -0.15),
        bodyLarge: GoogleFonts.inter(
            fontSize: 15, color: darkInk, height: 1.55),
        bodyMedium: GoogleFonts.inter(
            fontSize: 13, color: darkInk, height: 1.5),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF8A90B4)),
        labelSmall: GoogleFonts.jetBrainsMono(
            fontSize: 11, color: const Color(0xFF8A90B4), letterSpacing: 1.32),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkInk,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: darkInk, fontSize: 17, fontWeight: FontWeight.w600,
          letterSpacing: -0.34,
        ),
        iconTheme: const IconThemeData(color: darkInk, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161933),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
            color: const Color(0xFF8A90B4), fontSize: 14),
        hintStyle: GoogleFonts.inter(
            color: const Color(0xFF4A4F6A), fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: darkSurf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurf,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
            color: darkInk, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.inter(
            color: const Color(0xFFC2C6DC), fontSize: 13, height: 1.55),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkInk,
        contentTextStyle:
            GoogleFonts.inter(color: darkBg, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: darkBorder,
      ),
    );
  }
}
