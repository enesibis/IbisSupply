import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(RegisterRequested(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/dashboard');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF060D1F),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF07111F), Color(0xFF0B1A33), Color(0xFF0F2550)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Geri butonu
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Başlık
                        const Text('Hesap Oluştur',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text('IbisSupply ile ürünlerinizi takip edin',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),

                        const SizedBox(height: 32),

                        // Form kartı
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                children: [
                                  _DarkField(
                                    controller: _nameCtrl,
                                    hint: 'Ad Soyad',
                                    icon: Icons.person_outline,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Ad Soyad gerekli' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _DarkField(
                                    controller: _emailCtrl,
                                    hint: 'E-posta',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'E-posta gerekli';
                                      if (!v.contains('@')) return 'Geçerli e-posta girin';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _PasswordField(
                                    controller: _passCtrl,
                                    obscure: _obscure,
                                    onToggle: () => setState(() => _obscure = !_obscure),
                                  ),
                                  const SizedBox(height: 14),
                                  _DarkField(
                                    controller: _phoneCtrl,
                                    hint: 'Telefon (opsiyonel)',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Kayıt butonu
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final loading = state is AuthLoading;
                            return GestureDetector(
                              onTap: loading ? null : _submit,
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: loading
                                      ? LinearGradient(colors: [
                                          const Color(0xFF1565C0).withValues(alpha: 0.4),
                                          const Color(0xFF1565C0).withValues(alpha: 0.4),
                                        ])
                                      : const LinearGradient(
                                          colors: [Color(0xFF1976D2), Color(0xFF1E88E5)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: loading ? [] : [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: loading
                                      ? const SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : const Text('Kayıt Ol',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3)),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Giriş yap linki
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Zaten hesabın var mı?',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text('Giriş Yap',
                                  style: TextStyle(
                                      color: Color(0xFF42A5F5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Müşteri rolü notu
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF42A5F5), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Müşteri hesabı olarak kayıt olursunuz. QR tarama ve ürün takibi yapabilirsiniz.',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Şifre gerekli';
        if (v.length < 6) return 'En az 6 karakter';
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Şifre',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.35), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white38,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
