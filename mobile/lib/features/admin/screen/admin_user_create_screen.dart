import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);
const _success    = Color(0xFF0F7A4B);
const _successSoft= Color(0xFFE6F4EE);
const _danger     = Color(0xFFB91C1C);

// ── Role metadata ─────────────────────────────────────────────────────────────
class _RoleMeta {
  final String key;
  final String label;
  final String desc;
  final IconData icon;
  const _RoleMeta(this.key, this.label, this.desc, this.icon);
}

const _kRoles = [
  _RoleMeta('ADMIN',     'Admin',     'Tüm yetkilere sahip sistem yöneticisi', LucideIcons.shield),
  _RoleMeta('PRODUCER',  'Üretici',   'Ürün ve tarımsal kayıt yönetir',        LucideIcons.sprout),
  _RoleMeta('INSPECTOR', 'Denetçi',   'Kalite kontrol denetimlerini yürütür',  LucideIcons.search),
  _RoleMeta('LOGISTICS', 'Lojistik',  'Sevkiyat ve taşıma süreçlerini yönetir',LucideIcons.truck),
  _RoleMeta('WAREHOUSE', 'Depo',      'Depo ve stok operasyonlarını yönetir',  LucideIcons.package),
  _RoleMeta('RETAILER',  'Perakende', 'Perakende satış noktası operatörü',     LucideIcons.shoppingCart),
  _RoleMeta('CUSTOMER',  'Müşteri',   'Son tüketici — ürün takibi yapar',      LucideIcons.user),
];

class AdminUserCreateScreen extends StatelessWidget {
  const AdminUserCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(),
      child: const _CreateView(),
    );
  }
}

class _CreateView extends StatefulWidget {
  const _CreateView();
  @override
  State<_CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<_CreateView> {
  int _step = 0;

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRole = 'PRODUCER';
  bool   _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  bool _canProceed() {
    if (_step == 0) return _nameCtrl.text.trim().isNotEmpty && _emailCtrl.text.trim().isNotEmpty;
    if (_step == 1) return _passCtrl.text.length >= 6;
    return true;
  }

  void _next() { if (_step < 2) setState(() => _step++); }
  void _back() { if (_step > 0) setState(() => _step--); }

  void _submit(BuildContext ctx) {
    ctx.read<AdminBloc>().add(CreateUser(
      fullName: _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone:    _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim(),
      role:     _selectedRole,
    ));
  }

  void _snack(String msg, {Color color = _accent}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTheme.sans(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'Yeni\n',
                  style: GoogleFonts.fraunces(
                    fontSize: 32, fontWeight: FontWeight.w400,
                    color: _ink900, letterSpacing: -0.8, height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'Kullanıcı',
                  style: GoogleFonts.fraunces(
                    fontSize: 32, fontWeight: FontWeight.w400,
                    color: _ink900, letterSpacing: -0.8,
                    fontStyle: FontStyle.italic, height: 1.1,
                  ),
                ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Adım ${_step + 1}/3',
              style: AppTheme.sans(fontSize: 12, weight: FontWeight.w600, color: _accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ──────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        children: List.generate(3, (i) {
          final done   = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(children: [
              _StepCircle(index: i, active: active, done: done),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: done ? _accent : _line200,
                  ),
                ),
            ]),
          );
        })
        ..addAll([]),
      ),
    );
  }

  // ── Step 0: Identity ────────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('Ad Soyad'),
          _Field(
            hint: 'Ahmet Yılmaz',
            ctrl: _nameCtrl,
            icon: LucideIcons.user,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _Eyebrow('E-posta'),
          _Field(
            hint: 'ornek@email.com',
            ctrl: _emailCtrl,
            icon: LucideIcons.mail,
            type: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(LucideIcons.info, size: 14, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kullanıcıya sistem genelinde erişim sağlanacak. Bilgilerin doğruluğunu kontrol edin.',
                  style: AppTheme.sans(fontSize: 12, color: _accent),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Security ────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('Şifre'),
          _PasswordField(
            ctrl: _passCtrl,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'En az 6 karakter kullanın',
              style: AppTheme.sans(fontSize: 11, color: _ink400),
            ),
          ),
          const SizedBox(height: 16),
          _Eyebrow('Telefon (opsiyonel)'),
          _Field(
            hint: '+90 5xx xxx xx xx',
            ctrl: _phoneCtrl,
            icon: LucideIcons.phone,
            type: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          // Password strength indicator
          if (_passCtrl.text.isNotEmpty)
            _PasswordStrength(password: _passCtrl.text),
        ],
      ),
    );
  }

  // ── Step 2: Role ────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    final roleMeta = _kRoles.firstWhere((r) => r.key == _selectedRole);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('Kullanıcı Rolü'),
          ..._kRoles.map((r) {
            final sel = r.key == _selectedRole;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedRole = r.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? _accentSoft : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? _accent : _line200,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: sel ? _accent : _line100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(r.icon, size: 16,
                          color: sel ? Colors.white : _ink400),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              style: AppTheme.sans(
                                  fontSize: 13,
                                  weight: FontWeight.w600,
                                  color: sel ? _accent : _ink900)),
                          const SizedBox(height: 2),
                          Text(r.desc,
                              style: AppTheme.sans(
                                  fontSize: 11, color: sel ? _accent : _ink500)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel ? _accent : Colors.transparent,
                        border: Border.all(
                          color: sel ? _accent : _line200,
                          width: 1.5,
                        ),
                      ),
                      child: sel
                          ? const Icon(LucideIcons.check,
                              size: 10, color: Colors.white)
                          : const SizedBox.shrink(),
                    ),
                  ]),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _successSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _success.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(LucideIcons.userCheck, size: 14, color: _success),
                  const SizedBox(width: 8),
                  Text('Oluşturulacak Kullanıcı',
                      style: AppTheme.sans(
                          fontSize: 11, weight: FontWeight.w600, color: _success)),
                ]),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFB2DFCF)),
                const SizedBox(height: 10),
                _summaryRow('Ad Soyad', _nameCtrl.text.trim()),
                _summaryRow('E-posta', _emailCtrl.text.trim()),
                _summaryRow('Rol', roleMeta.label),
                if (_phoneCtrl.text.isNotEmpty)
                  _summaryRow('Telefon', _phoneCtrl.text.trim()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: AppTheme.sans(fontSize: 12, color: _success.withValues(alpha: 0.7))),
      ),
      Expanded(
        child: Text(value,
            style: AppTheme.sans(
                fontSize: 12, weight: FontWeight.w600, color: _success)),
      ),
    ]),
  );

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext ctx, bool isLoading) {
    final canGo = _canProceed();
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              border: const Border(top: BorderSide(color: _line200)),
            ),
            child: Row(children: [
              if (_step > 0)
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    height: 50, width: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _line100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _line200),
                    ),
                    child: const Icon(LucideIcons.arrowLeft,
                        size: 18, color: _ink900),
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: (isLoading || !canGo)
                      ? null
                      : (_step == 2 ? () => _submit(ctx) : _next),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 50,
                    decoration: BoxDecoration(
                      color: canGo && !isLoading
                          ? _ink900
                          : _ink900.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                _step == 2
                                    ? LucideIcons.userPlus
                                    : LucideIcons.arrowRight,
                                color: Colors.white, size: 17,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _step == 2 ? 'Oluştur' : 'Devam',
                                style: AppTheme.sans(
                                    fontSize: 14,
                                    weight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                            ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Yeni Kullanıcı',
            style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _line200),
        ),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is UserCreated) {
            _snack('Kullanıcı oluşturuldu', color: _success);
            context.pop();
          }
          if (state is AdminError) _snack(state.message, color: _danger);
        },
        builder: (context, state) {
          final isLoading = state is AdminLoading;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildStepIndicator(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim, child: child),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: [
                          _buildStep0(),
                          _buildStep1(),
                          _buildStep2(),
                        ][_step],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              _buildFooter(context, isLoading),
            ],
          );
        },
      ),
    );
  }
}

// ── Step circle ───────────────────────────────────────────────────────────────
class _StepCircle extends StatelessWidget {
  final int index;
  final bool active;
  final bool done;
  const _StepCircle({required this.index, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? _accent : (active ? _ink900 : _line100),
        border: Border.all(
          color: done || active ? Colors.transparent : _line200,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
            : Text(
                '${index + 1}',
                style: AppTheme.sans(
                  fontSize: 12,
                  weight: FontWeight.w600,
                  color: active ? Colors.white : _ink400,
                ),
              ),
      ),
    );
  }
}

// ── Shared input widgets ──────────────────────────────────────────────────────
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: AppTheme.sans(fontSize: 11, weight: FontWeight.w500, color: _ink400)),
  );
}

class _Field extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType type;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.hint,
    required this.ctrl,
    required this.icon,
    this.type = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      style: AppTheme.sans(fontSize: 14, color: _ink900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, size: 16, color: _ink400),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _line200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;

  const _PasswordField({
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      onChanged: onChanged,
      style: AppTheme.sans(fontSize: 14, color: _ink900),
      decoration: InputDecoration(
        hintText: 'En az 6 karakter',
        hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(LucideIcons.lock, size: 16, color: _ink400),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
        suffixIcon: IconButton(
          icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye,
              color: _ink400, size: 16),
          onPressed: onToggle,
        ),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _line200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
    );
  }
}

// ── Password strength bar ─────────────────────────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final color = s <= 1
        ? const Color(0xFFB91C1C)
        : s == 2
            ? const Color(0xFFB45309)
            : _success;
    final label = s <= 1 ? 'Zayıf' : s == 2 ? 'Orta' : 'Güçlü';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          ...List.generate(4, (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < s ? color : _line200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.sans(fontSize: 11, color: color,
              weight: FontWeight.w600)),
        ]),
      ],
    );
  }
}
