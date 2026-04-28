import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
// ── Tokens ────────────────────────────────────────────────────────────────────
const _ink900  = Color(0xFF0A0A0B);
const _ink400  = Color(0xFFA1A1AA);
const _line200 = Color(0xFFE4E4E7);
const _danger  = Color(0xFFB91C1C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'producer@ibissupply.com');
  final _passCtrl = TextEditingController(text: 'producer123');
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(LoginRequested(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
        child: Stack(
          children: [
            // Faint grid masked by radial gradient fading at top
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) => RadialGradient(
                  center: const Alignment(0, -0.56),
                  radius: 0.85,
                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                  stops: const [0.3, 0.75],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
            // Content
            SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Hero: mark + wordmark
                      Column(
                        children: [
                          const _HeroMark(size: 148),
                          const SizedBox(height: 22),
                          Text.rich(TextSpan(children: [
                            TextSpan(
                              text: 'Ibis',
                              style: GoogleFonts.fraunces(
                                fontSize: 38,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.ink,
                                letterSpacing: 38 * -0.025,
                              ),
                            ),
                            TextSpan(
                              text: 'Supply',
                              style: GoogleFonts.fraunces(
                                fontSize: 38,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.accent,
                                letterSpacing: 38 * -0.025,
                              ),
                            ),
                          ])),
                        ],
                      ),
                      const SizedBox(height: 36),
                      // E-posta
                      _LoginField(
                        controller: _emailCtrl,
                        label: 'E-posta',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'E-posta gerekli';
                          if (!v.contains('@')) return 'Geçerli e-posta girin';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Şifre
                      _LoginField(
                        controller: _passCtrl,
                        label: 'Şifre',
                        icon: LucideIcons.lock,
                        obscureText: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Şifre gerekli';
                          if (v.length < 6) return 'En az 6 karakter';
                          return null;
                        },
                      ),
                      // Şifremi unuttum
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(top: 6, bottom: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {},
                          child: Text(
                            'Şifremi unuttum',
                            style: AppTheme.sans(
                              fontSize: 12,
                              weight: FontWeight.w500,
                              color: const Color(0xFF52525B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Primary: Giriş yap
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading;
                          return _PrimaryButton(
                            label: 'Giriş yap →',
                            loading: loading,
                            onTap: loading ? null : _submit,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Secondary: QR
                      _SecondaryButton(
                        label: 'QR ile ürün sorgula',
                        icon: LucideIcons.qrCode,
                        onTap: () => context.push('/qr-public'),
                      ),
                      const SizedBox(height: 28),
                      // Footer
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(
                              text: 'Hesabınız yok mu? ',
                              style: AppTheme.sans(
                                fontSize: 13,
                                color: const Color(0xFF52525B),
                              ),
                            ),
                            TextSpan(
                              text: 'Kayıt olun',
                              style: AppTheme.sans(
                                fontSize: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                          ])),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
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

// ── Faint 32×32 grid background ───────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF4F4F5)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Distributed-ledger logo mark ──────────────────────────────────────────────
class _HeroMark extends StatelessWidget {
  final double size;
  const _HeroMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeroMarkPainter()),
    );
  }
}

class _HeroMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0 0 64 64 → scale to size
    final s = size.width / 64;
    canvas.scale(s, s);

    const cx = 32.0;
    const cy = 32.0;
    const accent = Color(0xFF3F3FE8);
    const ink = Color(0xFF0A0A0B);

    // Node positions (matching JSX)
    final nodes = [
      const Offset(32, 10),
      const Offset(51, 21),
      const Offset(51, 43),
      const Offset(32, 54),
      const Offset(13, 43),
      const Offset(13, 21),
    ];

    // Spoke lines center → nodes
    final spokePaint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (final n in nodes) {
      canvas.drawLine(const Offset(cx, cy), n, spokePaint);
    }

    // Outer hexagon
    final hexPath = Path()
      ..moveTo(32, 4)
      ..lineTo(54, 17)
      ..lineTo(54, 43)
      ..lineTo(32, 56)
      ..lineTo(10, 43)
      ..lineTo(10, 17)
      ..close();
    canvas.drawPath(
      hexPath,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeJoin = StrokeJoin.round,
    );

    // Peripheral nodes (white fill + ink stroke)
    final nodeStroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final nodeFill = Paint()..color = Colors.white;
    for (final n in nodes) {
      canvas.drawCircle(n, 3.2, nodeFill);
      canvas.drawCircle(n, 3.2, nodeStroke);
    }

    // Center circle (accent fill)
    canvas.drawCircle(const Offset(cx, cy), 6.5, Paint()..color = accent);

    // Checkmark (white)
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path()
      ..moveTo(29, 32)
      ..lineTo(31.2, 34.2)
      ..lineTo(35.5, 29.8);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_HeroMarkPainter _) => false;
}

// ── Input field ───────────────────────────────────────────────────────────────
class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onToggleObscure,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTheme.sans(fontSize: 15, color: _ink900),
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: AppTheme.sans(fontSize: 14, color: _ink400),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _ink400, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: _ink400,
                  size: 18,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _danger, width: 1.5),
        ),
        errorStyle: AppTheme.sans(color: _danger, fontSize: 11),
      ),
    );
  }
}

// ── Primary button (indigo, full width, 52px) ─────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutQuart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 52,
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xFF3636D4)
                : AppTheme.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.label,
                    style: AppTheme.sans(
                      fontSize: 15,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Secondary button (white + 1px border, full width, 52px) ───────────────────
class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.ink,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: AppTheme.sans(fontSize: 14, weight: FontWeight.w600),
        ),
      ),
    );
  }
}
