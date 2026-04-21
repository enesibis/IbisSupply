import 'package:flutter/material.dart';

/// Tema-aware renk token'ları. Her widget'ta `IbisColors.of(context)` ile çağır.
///
/// Palet: kirli beyaz zemin · mürekkep metin · olgun orman yeşili accent · sıcak amber uyarı
class IbisColors {
  final bool isDark;

  // ── Arka plan katmanları ──────────────────────────────────────────────────
  final Color pageBg;    // Scaffold zemin — oklch(0.98 0.005 95)
  final Color surface;   // Kart yüzeyi
  final Color cardBg;    // İkincil kart
  final Color dialogBg;  // AlertDialog

  // ── Metin ─────────────────────────────────────────────────────────────────
  final Color text;           // Birincil mürekkep — oklch(0.15 0.01 95)
  final Color textSecondary;  // İkincil metin
  final Color textMuted;      // Soluk metin
  final Color textDisabled;   // Pasif metin

  // ── Çizgi / kenarlık — hairline ───────────────────────────────────────────
  final Color border;       // Normal kenarlık (1px)
  final Color borderLight;  // Çok ince kenarlık

  // ── Input / chip ──────────────────────────────────────────────────────────
  final Color inputFill;
  final Color chipBg;

  // ── Accent: olgun orman yeşili — oklch(0.48 0.12 145) ─────────────────────
  final Color accent;
  final Color accentLight;  // Tinted bg (rozet, chip arkaplanı)

  // ── Uyarı: sıcak amber ────────────────────────────────────────────────────
  final Color amber;
  final Color amberLight;

  // ── Hata ──────────────────────────────────────────────────────────────────
  final Color error;
  final Color errorLight;

  // ── Shimmer ───────────────────────────────────────────────────────────────
  final Color shimmerBase;
  final Color shimmerHighlight;

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
  });

  // ── Light: kirli beyaz + mürekkep editorial ───────────────────────────────
  static const _light = IbisColors._(
    isDark: false,
    pageBg:   Color(0xFFF9F8F3),  // oklch(0.98 0.005 95) ≈ ılık kırık beyaz
    surface:  Color(0xFFF4F3EE),
    cardBg:   Color(0xFFEEECE7),
    dialogBg: Color(0xFFF9F8F3),
    text:         Color(0xFF1C1B16),  // oklch(0.15 0.01 95) ≈ derin mürekkep
    textSecondary:Color(0xFF4A4942),
    textMuted:    Color(0xFF78776E),
    textDisabled: Color(0xFFB2B0A8),
    border:      Color(0xFFD6D4CC),  // hairline — ince ama görünür
    borderLight: Color(0xFFE6E4DC),
    inputFill: Color(0xFFF4F3EE),
    chipBg:    Color(0xFFEEECE7),
    accent:      Color(0xFF2E6840),  // oklch(0.48 0.12 145) ≈ orman yeşili
    accentLight: Color(0xFFDEEDE4),
    amber:      Color(0xFFC47A0F),   // sıcak amber uyarı
    amberLight: Color(0xFFFAEED3),
    error:      Color(0xFFAD2020),
    errorLight: Color(0xFFF9E0E0),
    shimmerBase:      Color(0xFFECEAE2),
    shimmerHighlight: Color(0xFFF4F3EE),
  );

  // ── Dark: koyu kağıt + açık mürekkep ─────────────────────────────────────
  static const _dark = IbisColors._(
    isDark: true,
    pageBg:   Color(0xFF1A1916),
    surface:  Color(0xFF222019),
    cardBg:   Color(0xFF2A2820),
    dialogBg: Color(0xFF222019),
    text:         Color(0xFFF2F0EB),
    textSecondary:Color(0xFFB8B5AD),
    textMuted:    Color(0xFF7A7870),
    textDisabled: Color(0xFF484640),
    border:      Color(0xFF3C3A30),
    borderLight: Color(0xFF2E2C24),
    inputFill: Color(0xFF2A2820),
    chipBg:    Color(0xFF302E26),
    accent:      Color(0xFF4A9460),  // açık yeşil — dark'ta okunabilir
    accentLight: Color(0xFF1A3326),
    amber:      Color(0xFFD4920A),
    amberLight: Color(0xFF332510),
    error:      Color(0xFFD44040),
    errorLight: Color(0xFF3A1616),
    shimmerBase:      Color(0xFF282620),
    shimmerHighlight: Color(0xFF302E28),
  );

  static IbisColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }
}
