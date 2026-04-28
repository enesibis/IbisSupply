import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink600     = Color(0xFF52525B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _line200    = Color(0xFFE4E4E7);
const _danger     = Color(0xFFB91C1C);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
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
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        phone:    _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/dashboard');
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message,
                style: AppTheme.sans(color: Colors.white)),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: _ink900),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _line200),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.fraunces(
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.6,
                            height: 1.15,
                            color: _ink900,
                          ),
                          children: const [
                            TextSpan(text: 'Hesap '),
                            TextSpan(
                              text: 'oluşturun.',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic, color: _accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'IbisSupply ile ürünlerinizi takip edin',
                        style: AppTheme.sans(fontSize: 13, color: _ink500),
                      ),
                      const SizedBox(height: 32),

                      // Ad Soyad
                      _FieldLabel('Ad Soyad'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _nameCtrl,
                        hint: 'Ad Soyad',
                        icon: LucideIcons.user,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ad Soyad gerekli' : null,
                      ),
                      const SizedBox(height: 14),

                      // E-posta
                      _FieldLabel('E-posta'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _emailCtrl,
                        hint: 'ornek@email.com',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'E-posta gerekli';
                          if (!v.contains('@')) return 'Geçerli e-posta girin';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Şifre
                      _FieldLabel('Şifre'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _passCtrl,
                        hint: 'En az 6 karakter',
                        icon: LucideIcons.lock,
                        obscureText: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Şifre gerekli';
                          if (v.length < 6) return 'En az 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Telefon
                      _FieldLabel('Telefon (opsiyonel)'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _phoneCtrl,
                        hint: '+90 5xx xxx xx xx',
                        icon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 28),

                      // Kayıt butonu
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading;
                          return GestureDetector(
                            onTap: loading ? null : _submit,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              height: 52,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: loading
                                    ? _ink900.withValues(alpha: 0.45)
                                    : _ink900,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: loading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Text('Kayıt Ol',
                                        style: AppTheme.sans(
                                            fontSize: 15,
                                            weight: FontWeight.w600,
                                            color: Colors.white)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Giriş linki
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(
                              text: 'Zaten hesabın var mı? ',
                              style: AppTheme.sans(
                                  fontSize: 13, color: _ink500),
                            ),
                            TextSpan(
                              text: 'Giriş Yap',
                              style: AppTheme.sans(
                                  fontSize: 13,
                                  weight: FontWeight.w600,
                                  color: _ink900),
                            ),
                          ])),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          const Icon(LucideIcons.info,
                              color: _accent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Müşteri hesabı olarak kayıt olursunuz. '
                              'QR tarama ve ürün takibi yapabilirsiniz.',
                              style: AppTheme.sans(
                                  fontSize: 12, color: _ink600),
                            ),
                          ),
                        ]),
                      ),
                    ],
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTheme.sans(
            fontSize: 12, weight: FontWeight.w500, color: _ink600));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onToggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTheme.sans(fontSize: 15, color: _ink900),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sans(fontSize: 14, color: _ink400),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _ink400, size: 17),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 46, minHeight: 46),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: _ink400, size: 17,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent, width: 1.5),
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
