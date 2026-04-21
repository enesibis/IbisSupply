import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/ibis_colors.dart';

/// Editorial liste kartı — 3px solid sol accent çizgisi · gölge yok · 8px radius.
class IbisListTile extends StatelessWidget {
  final Color accentColor;
  final Widget icon;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? badge;
  final VoidCallback? onTap;

  const IbisListTile({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Sol accent bar — solid 3px
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),

              // İçerik
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Row(
                    children: [
                      // İkon — sade kare kutu
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: icon,
                      ),
                      const SizedBox(width: 13),

                      // Metin alanı
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            title,
                            if (subtitle != null) ...[
                              const SizedBox(height: 3),
                              subtitle!,
                            ],
                            if (badge != null) ...[
                              const SizedBox(height: 6),
                              badge!,
                            ],
                          ],
                        ),
                      ),

                      // Trailing
                      if (trailing != null)
                        trailing!
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: c.textDisabled,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Durum rozeti — hairline kenarlıklı, sade.
class IbisStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const IbisStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Monospace veri stripe — hash, batch kodu, TX hash gibi teknik değerler için.
class IbisMonoChip extends StatelessWidget {
  final String value;
  final Color? color;

  const IbisMonoChip({super.key, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Text(
        value,
        style: GoogleFonts.dmMono(
          color: color ?? c.textMuted,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Boş durum — minimal, editorial.
class IbisEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const IbisEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border, width: 1),
              ),
              child: Icon(icon, size: 32, color: c.textDisabled),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.instrumentSerif(
                color: c.text,
                fontSize: 20,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: c.textMuted,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hata durumu — minimal, sade.
class IbisErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const IbisErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.error.withValues(alpha: 0.20), width: 1),
              ),
              child: Icon(Icons.wifi_off_rounded, size: 28, color: c.error),
            ),
            const SizedBox(height: 18),
            Text(
              'Bağlantı Hatası',
              style: GoogleFonts.dmSans(
                  color: c.text, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat FAB — gradient yok, solid accent rengi.
class IbisFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  /// İlk renk accent olarak kullanılır, gradient kaldırıldı.
  final List<Color> colors;

  const IbisFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.colors = const [Color(0xFF2E6840), Color(0xFF2E6840)],
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = colors.first;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
