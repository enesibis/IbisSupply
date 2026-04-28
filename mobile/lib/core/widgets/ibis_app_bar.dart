import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/ibis_colors.dart';

/// IbisSupply editorial AppBar.
/// Flat kirli-beyaz zemin · 1px hairline alt kenarlık · gölge yok · blur yok.
class IbisAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  /// Accent çizgisi rengi — varsayılan orman yeşili
  final Color? accentColor;

  const IbisAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.leading,
    this.accentColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final lineColor = accentColor ?? c.accent;
    final overlayStyle = c.isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: c.pageBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    if (leading != null)
                      leading!
                    else if (Navigator.of(context).canPop())
                      _BackButton(c: c),

                    Expanded(
                      child: centerTitle
                          ? Center(child: _Title(title: title, c: c))
                          : Padding(
                              padding: EdgeInsets.only(
                                left: Navigator.of(context).canPop() ? 4 : 20,
                              ),
                              child: _Title(title: title, c: c),
                            ),
                    ),

                    if (actions != null) ...actions!,
                    if (actions == null) const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            // Hairline kenarlık — accent renginde ince çizgi
            Container(height: 1, color: lineColor.withValues(alpha: 0.18)),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final IbisColors c;
  const _Title({required this.title, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        color: c.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _BackButton extends StatelessWidget {
  final IbisColors c;
  const _BackButton({required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: kToolbarHeight,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: c.border, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: c.textSecondary,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}
