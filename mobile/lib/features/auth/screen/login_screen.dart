import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ibis_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _logoCtrl;
  late AnimationController _formCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _formCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));
    _formFade = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _formCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Düz zemin — gradient ve glow yok
            Container(color: c.pageBg),

            // İçerik
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: screenHeight - MediaQuery.of(context).padding.top),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.07),

                      // ── Branding ──────────────────────────────────
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: c.border, width: 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_shipping_rounded,
                                      color: AppTheme.accent,
                                      size: 54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gıda Tedarik Zinciri Platformu',
                                style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.07),

                      // ── Form kartı ────────────────────────────────
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _FormCard(
                              isDark: c.isDark,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hoş Geldiniz',
                                              style: AppTheme.serif(fontSize: 22, color: c.text),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Hesabınıza giriş yapın',
                                              style: TextStyle(
                                                color: c.textMuted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        _SecureBadge(),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    _FieldLabel(text: 'E-posta'),
                                    const SizedBox(height: 8),
                                    _IbisInput(
                                      controller: _emailController,
                                      hint: 'ornek@sirket.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'E-posta gerekli';
                                        if (!v.contains('@')) return 'Geçerli e-posta girin';
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 18),

                                    _FieldLabel(text: 'Şifre'),
                                    const SizedBox(height: 8),
                                    _IbisInput(
                                      controller: _passwordController,
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      onToggleObscure: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Şifre gerekli';
                                        if (v.length < 6) return 'En az 6 karakter';
                                        return null;
                                      },
                                      onSubmitted: (_) => _submit(),
                                    ),

                                    const SizedBox(height: 28),

                                    BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, state) {
                                        final loading = state is AuthLoading;
                                        return _LoginButton(
                                          loading: loading,
                                          onTap: loading ? null : _submit,
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Hesabın yok mu?',
                                            style: TextStyle(
                                                color: c.textMuted, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => context.push('/register'),
                                          child: const Text('Kayıt Ol',
                                              style: TextStyle(
                                                  color: AppTheme.accent,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _formFade,
                        child: TextButton.icon(
                          onPressed: () => context.push('/qr-public'),
                          icon: Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 15,
                            color: c.textMuted,
                          ),
                          label: Text(
                            'Ürün Sorgula — Giriş Gerektirmez',
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
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

// ── Form kart wrapper ─────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _FormCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: child,
    );
  }
}

// ── Güvenli rozet ────────────────────────────────────────────────────────────
class _SecureBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.accentLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 11, color: c.accent),
          const SizedBox(width: 4),
          Text(
            'Güvenli',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.accent),
          ),
        ],
      ),
    );
  }
}

// ── Label ────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.textSecondary,
      ),
    );
  }
}

// ── Input ────────────────────────────────────────────────────────────────────
class _IbisInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _IbisInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onToggleObscure,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: c.text, fontSize: 15),
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textDisabled, fontSize: 14),
        prefixIcon: Icon(icon, color: c.textMuted, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: c.textMuted,
                  size: 19,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: c.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
        errorStyle: TextStyle(color: c.error, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

// ── Giriş Butonu ─────────────────────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _LoginButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: loading
              ? AppTheme.accent.withValues(alpha: 0.45)
              : AppTheme.accent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
