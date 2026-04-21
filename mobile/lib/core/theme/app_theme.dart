import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// IbisSupply Editorial Design System
///
/// Zemin: kirli beyaz (#F9F8F3)  Metin: derin mürekkep (#1C1B16)
/// Accent: orman yeşili (#2E6840)  Uyarı: sıcak amber (#C47A0F)
/// Tipografi: Instrument Serif (başlık) · DM Sans (UI) · DM Mono (teknik)
/// Geometri: max 8px radius · 1px hairline border · gölge yok
class AppTheme {
  // ── Renk sabitleri ────────────────────────────────────────────────────────
  static const Color ink       = Color(0xFF1C1B16);  // derin mürekkep
  static const Color parchment = Color(0xFFF9F8F3);  // kirli beyaz zemin
  static const Color accent    = Color(0xFF2E6840);  // orman yeşili
  static const Color amber     = Color(0xFFC47A0F);  // sıcak amber
  static const Color error     = Color(0xFFAD2020);  // hata

  // Risk seviyeleri — amber ve hata paleti tutarlı
  static const Color riskLow      = Color(0xFF2E6840);
  static const Color riskMedium   = Color(0xFFC47A0F);
  static const Color riskHigh     = Color(0xFFAD2020);
  static const Color riskCritical = Color(0xFF7A0D0D);

  // ── Tipografi yardımcıları ────────────────────────────────────────────────

  /// Başlık / display → Instrument Serif
  static TextStyle serif({
    double fontSize = 24,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = -0.3,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.instrumentSerif(
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? ink,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: style,
      );

  /// UI metin → DM Sans
  static TextStyle sans({
    double fontSize = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? ink,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Hash / ID / teknik veri → DM Mono
  static TextStyle mono({
    double fontSize = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0.3,
  }) =>
      GoogleFonts.dmMono(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final dmSansText = GoogleFonts.dmSansTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDEEDE4),
        onPrimaryContainer: Color(0xFF1A3D28),
        secondary: amber,
        onSecondary: Colors.white,
        surface: Color(0xFFF4F3EE),
        onSurface: ink,
        surfaceContainerHighest: Color(0xFFEEECE7),
        error: error,
        onError: Colors.white,
        outline: Color(0xFFD6D4CC),
      ),
      scaffoldBackgroundColor: parchment,
      textTheme: dmSansText.copyWith(
        displayLarge: GoogleFonts.instrumentSerif(
            fontSize: 48, fontWeight: FontWeight.w400, color: ink, height: 1.15, letterSpacing: -0.5),
        displayMedium: GoogleFonts.instrumentSerif(
            fontSize: 36, fontWeight: FontWeight.w400, color: ink, height: 1.2, letterSpacing: -0.3),
        displaySmall: GoogleFonts.instrumentSerif(
            fontSize: 28, fontWeight: FontWeight.w400, color: ink, height: 1.25, letterSpacing: -0.2),
        headlineLarge: GoogleFonts.instrumentSerif(
            fontSize: 24, fontWeight: FontWeight.w400, color: ink, height: 1.3),
        headlineMedium: GoogleFonts.instrumentSerif(
            fontSize: 20, fontWeight: FontWeight.w400, color: ink, height: 1.35),
        headlineSmall: GoogleFonts.dmSans(
            fontSize: 17, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.2),
        titleLarge: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.1),
        titleMedium: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: ink),
        titleSmall: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4A4942)),
        bodyLarge: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w400, color: ink, height: 1.55),
        bodyMedium: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w400, color: ink, height: 1.5),
        bodySmall: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF78776E), height: 1.45),
        labelLarge: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: ink, letterSpacing: 0.1),
        labelMedium: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF4A4942)),
        labelSmall: GoogleFonts.dmMono(
            fontSize: 10, fontWeight: FontWeight.w400, color: const Color(0xFF78776E), letterSpacing: 0.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: parchment,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: ink, size: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD6D4CC),
          disabledForegroundColor: const Color(0xFF78776E),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: const BorderSide(color: Color(0xFF2E6840), width: 1),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F3EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD6D4CC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD6D4CC), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: const Color(0xFF78776E), fontSize: 13),
        hintStyle: GoogleFonts.dmSans(color: const Color(0xFFB2B0A8), fontSize: 13),
        errorStyle: GoogleFonts.dmSans(color: error, fontSize: 11),
        prefixIconColor: const Color(0xFF78776E),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: const Color(0xFFF4F3EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFD6D4CC), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: parchment,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFD6D4CC), width: 1),
        ),
        titleTextStyle: GoogleFonts.dmSans(
          color: ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          color: const Color(0xFF4A4942),
          fontSize: 13,
          height: 1.55,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.dmSans(color: parchment, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEECE7),
        labelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: ink),
        side: const BorderSide(color: Color(0xFFD6D4CC), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE6E4DC),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
        subtitleTextStyle: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF78776E)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFF78776E),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : const Color(0xFFD6D4CC),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Color(0xFFD6D4CC), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: Color(0xFFD6D4CC),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final dmSansText = GoogleFonts.dmSansTextTheme(base.textTheme);
    const darkAccent = Color(0xFF4A9460);
    const darkBg    = Color(0xFF1A1916);
    const darkSurf  = Color(0xFF222019);
    const darkInk   = Color(0xFFF2F0EB);
    const darkBorder = Color(0xFF3C3A30);

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        onPrimary: Color(0xFF0D2218),
        primaryContainer: Color(0xFF1A3326),
        onPrimaryContainer: Color(0xFFB8DECA),
        secondary: Color(0xFFD4920A),
        onSecondary: Color(0xFF1A0E00),
        surface: darkSurf,
        onSurface: darkInk,
        surfaceContainerHighest: Color(0xFF2A2820),
        error: Color(0xFFD44040),
        onError: Color(0xFF1A0000),
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: dmSansText.copyWith(
        displayLarge: GoogleFonts.instrumentSerif(
            fontSize: 48, color: darkInk, height: 1.15, letterSpacing: -0.5),
        displayMedium: GoogleFonts.instrumentSerif(
            fontSize: 36, color: darkInk, height: 1.2),
        headlineLarge: GoogleFonts.instrumentSerif(
            fontSize: 24, color: darkInk, height: 1.3),
        headlineSmall: GoogleFonts.dmSans(
            fontSize: 17, fontWeight: FontWeight.w600, color: darkInk, letterSpacing: -0.2),
        titleLarge: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w600, color: darkInk),
        bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: darkInk, height: 1.55),
        bodyMedium: GoogleFonts.dmSans(fontSize: 13, color: darkInk, height: 1.5),
        bodySmall: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF7A7870)),
        labelSmall: GoogleFonts.dmMono(
            fontSize: 10, color: const Color(0xFF7A7870), letterSpacing: 0.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkInk,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          color: darkInk,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: darkInk, size: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: const Color(0xFF0D2218),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2820),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: const Color(0xFF7A7870), fontSize: 13),
        hintStyle: GoogleFonts.dmSans(color: const Color(0xFF484640), fontSize: 13),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: darkSurf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurf,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder),
        ),
        titleTextStyle: GoogleFonts.dmSans(
            color: darkInk, fontSize: 15, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.dmSans(
            color: const Color(0xFFB8B5AD), fontSize: 13, height: 1.55),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkInk,
        contentTextStyle: GoogleFonts.dmSans(color: darkBg, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkAccent,
        foregroundColor: const Color(0xFF0D2218),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkAccent,
        linearTrackColor: darkBorder,
      ),
    );
  }
}
