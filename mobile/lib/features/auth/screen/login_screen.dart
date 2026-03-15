import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

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
                backgroundColor: const Color(0xFFB71C1C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arka plan
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF07111F), Color(0xFF0B1A33), Color(0xFF0F2550)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Hafif dekoratif ışık — sadece üstte, ince
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenHeight * 0.45,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF1565C0).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // İçerik
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.07),

                      // ── Branding alanı ───────────────────────────
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Column(
                            children: [
                              // Logo kutusu
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(34),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                                      blurRadius: 70,
                                      spreadRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_shipping_rounded,
                                      color: AppTheme.primary,
                                      size: 54,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Alt başlık
                              Text(
                                'Gıda Tedarik Zinciri Platformu',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.07),

                      // ── Form kartı ───────────────────────────────
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Başlık satırı
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Hoş Geldiniz',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Hesabınıza giriş yapın',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.4),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            _SecureBadge(),
                                          ],
                                        ),

                                        const SizedBox(height: 28),

                                        // E-posta
                                        _FieldLabel(text: 'E-posta'),
                                        const SizedBox(height: 8),
                                        _DarkInput(
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

                                        // Şifre
                                        _FieldLabel(text: 'Şifre'),
                                        const SizedBox(height: 8),
                                        _DarkInput(
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

                                        // Giriş butonu
                                        BlocBuilder<AuthBloc, AuthState>(
                                          builder: (context, state) {
                                            final loading = state is AuthLoading;
                                            return _LoginButton(
                                              loading: loading,
                                              onTap: loading ? null : _submit,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // QR kısayolu
                      FadeTransition(
                        opacity: _formFade,
                        child: TextButton.icon(
                          onPressed: () => context.push('/qr-public'),
                          icon: Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          label: Text(
                            'Ürün Sorgula — Giriş Gerektirmez',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13,
                            ),
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

// ── Güvenli rozet ────────────────────────────────────────────────────────────
class _SecureBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 11, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            'Güvenli',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
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
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

// ── Input ────────────────────────────────────────────────────────────────────
class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _DarkInput({
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
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.22), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 19,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: loading
              ? LinearGradient(colors: [
                  const Color(0xFF1565C0).withValues(alpha: 0.45),
                  const Color(0xFF1565C0).withValues(alpha: 0.45),
                ])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1976D2), Color(0xFF1E88E5)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
