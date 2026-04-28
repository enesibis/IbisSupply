import 'package:flutter/material.dart';

/// IbisSupply renk token sistemi — v3 (white-focused, premium restraint)
/// Palet: #FFFFFF zemin · #0A0A0B mürekkep · #3F3FE8 indigo aksan
class IbisColors {
  final bool isDark;

  // ── Arka plan ──────────────────────────────────────────────────────────────
  final Color pageBg;   // Scaffold zemin
  final Color surface;  // Kart yüzeyi
  final Color cardBg;   // İkincil kart / subtle bg
  final Color dialogBg; // AlertDialog

  // ── Metin ──────────────────────────────────────────────────────────────────
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  // ── Kenarlık ───────────────────────────────────────────────────────────────
  final Color border;
  final Color borderLight;

  // ── Input / chip ───────────────────────────────────────────────────────────
  final Color inputFill;
  final Color chipBg;

  // ── Aksan: İndigo ──────────────────────────────────────────────────────────
  final Color accent;
  final Color accentLight;

  // ── Uyarı: Amber ───────────────────────────────────────────────────────────
  final Color amber;
  final Color amberLight;

  // ── Hata: Kırmızı ─────────────────────────────────────────────────────────
  final Color error;
  final Color errorLight;

  // ── Shimmer ────────────────────────────────────────────────────────────────
  final Color shimmerBase;
  final Color shimmerHighlight;

  // ── Ekstra ─────────────────────────────────────────────────────────────────
  /// Koyu mürekkep — hero section'lar için (her iki temada aynı)
  final Color night;
  /// Mor ikincil aksan
  final Color purple;
  final Color purpleLight;

  const IbisColors._({
    required this.isDark,
    required this.pageBg,
    required this.surface,
    required this.cardBg,
    required this.dialogBg,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.border,
    required this.borderLight,
    required this.inputFill,
    required this.chipBg,
    required this.accent,
    required this.accentLight,
    required this.amber,
    required this.amberLight,
    required this.error,
    required this.errorLight,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.night,
    required this.purple,
    required this.purpleLight,
  });

  // ── Light ──────────────────────────────────────────────────────────────────
  static const _light = IbisColors._(
    isDark: false,
    pageBg:   Color(0xFFFFFFFF),
    surface:  Color(0xFFFFFFFF),
    cardBg:   Color(0xFFFAFAFA),
    dialogBg: Color(0xFFFFFFFF),
    text:          Color(0xFF0A0A0B),
    textSecondary: Color(0xFF52525B),
    textMuted:     Color(0xFFA1A1AA),
    textDisabled:  Color(0xFFD4D4D8),
    border:      Color(0xFFE4E4E7),
    borderLight: Color(0xFFF4F4F5),
    inputFill: Color(0xFFF4F4F5),
    chipBg:    Color(0xFFF4F4F5),
    accent:      Color(0xFF3F3FE8),
    accentLight: Color(0xFFEEEEFE),
    amber:      Color(0xFFB45309),
    amberLight: Color(0xFFFBF1E1),
    error:      Color(0xFFB91C1C),
    errorLight: Color(0xFFFBE8E8),
    shimmerBase:      Color(0xFFF4F4F5),
    shimmerHighlight: Color(0xFFFFFFFF),
    night:       Color(0xFF0A0A0B),
    purple:      Color(0xFF7B61FF),
    purpleLight: Color(0xFFF0EDFF),
  );

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const _dark = IbisColors._(
    isDark: true,
    pageBg:   Color(0xFF08091A),
    surface:  Color(0xFF0F1128),
    cardBg:   Color(0xFF161933),
    dialogBg: Color(0xFF0F1128),
    text:          Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC2C6DC),
    textMuted:     Color(0xFF8A90B4),
    textDisabled:  Color(0xFF4A4F6A),
    border:      Color(0x1EFFFFFF),
    borderLight: Color(0x0FFFFFFF),
    inputFill: Color(0xFF161933),
    chipBg:    Color(0xFF1F2240),
    accent:      Color(0xFF3F3FE8),
    accentLight: Color(0x1F3F3FE8),
    amber:      Color(0xFFB45309),
    amberLight: Color(0xFF2A2010),
    error:      Color(0xFFB91C1C),
    errorLight: Color(0xFF2A1010),
    shimmerBase:      Color(0xFF161933),
    shimmerHighlight: Color(0xFF1F2240),
    night:       Color(0xFF0A0A0B),
    purple:      Color(0xFF7B61FF),
    purpleLight: Color(0xFF1F1B40),
  );

  static IbisColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}
