import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/bloc/theme_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _batchCount;
  int? _shipmentCount;

  static const _roleLabels = {
    'ADMIN': 'Admin',
    'PRODUCER': 'Üretici',
    'PROCESSOR': 'İşleyici',
    'LOGISTICS': 'Lojistik',
    'WAREHOUSE': 'Depo',
    'INSPECTOR': 'Denetçi',
    'RETAILER': 'Satıcı',
    'CUSTOMER': 'Müşteri',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = ApiClient.create();
      final bRes = await dio.get('/batches');
      final sRes = await dio.get('/shipments');
      if (mounted) {
        setState(() {
          _batchCount = (bRes.data as List).length;
          _shipmentCount = (sRes.data as List).length;
        });
      }
    } catch (_) {}
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        currentCtrl: TextEditingController(),
        newCtrl: TextEditingController(),
        confirmCtrl: TextEditingController(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthAuthenticated) return const SizedBox.shrink();

    final initials = state.fullName.isNotEmpty
        ? state.fullName
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    final roleLabel = _roleLabels[state.role] ?? state.role;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              expandedTitleScale: 1.0,
              title: Text(
                'Profil',
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.ink,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings, size: 18),
                color: AppTheme.ink,
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child:
                  Container(height: 1, color: const Color(0xFFE4E4E7)),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Profile card ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.ink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.fraunces(
                                fontSize: 30,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.fullName,
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.24,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.email,
                          style: AppTheme.sans(
                              fontSize: 13,
                              color: const Color(0xFF71717A)),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          children: [
                            _Pill(
                              label: roleLabel,
                              fg: AppTheme.accent,
                              bg: const Color(0xFFEEEEFE),
                            ),
                            if (state.orgName != null &&
                                state.orgName!.isNotEmpty)
                              _Pill(
                                label: state.orgName!,
                                fg: const Color(0xFF52525B),
                                bg: const Color(0xFFF4F4F5),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats row ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: _batchCount != null
                              ? '$_batchCount'
                              : '—',
                          label: 'Batch',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          value: _shipmentCount != null
                              ? '$_shipmentCount'
                              : '—',
                          label: 'Sevkiyat',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: _StatCard(value: '—', label: 'Kalite'),
                      ),
                    ],
                  ),
                ),

                // ── Account menu ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow('Hesap'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: Column(
                          children: [
                            _MenuRow(
                              icon: LucideIcons.user,
                              label: 'Kişisel bilgiler',
                              onTap: () {},
                            ),
                            const _Divider(),
                            _MenuRow(
                              icon: LucideIcons.lock,
                              label: 'Şifre değiştir',
                              onTap: () =>
                                  _showChangePasswordDialog(context),
                            ),
                            const _Divider(),
                            _MenuRow(
                              icon: LucideIcons.bell,
                              label: 'Bildirim ayarları',
                              onTap: () {},
                            ),
                            const _Divider(),
                            _MenuRow(
                              icon: LucideIcons.globe,
                              label: 'Dil',
                              value: 'Türkçe',
                              onTap: () {},
                            ),
                            const _Divider(),
                            // Theme toggle
                            BlocBuilder<ThemeCubit, ThemeMode>(
                              builder: (ctx, themeMode) {
                                final isDark =
                                    themeMode == ThemeMode.dark;
                                return _MenuRow(
                                  icon: isDark
                                      ? LucideIcons.moon
                                      : LucideIcons.sun,
                                  label: 'Görünüm',
                                  value: isDark ? 'Koyu' : 'Açık',
                                  onTap: () =>
                                      ctx.read<ThemeCubit>().toggle(),
                                );
                              },
                            ),
                            const _Divider(),
                            _MenuRow(
                              icon: LucideIcons.logOut,
                              label: 'Çıkış yap',
                              danger: true,
                              onTap: () {
                                context
                                    .read<AuthBloc>()
                                    .add(LogoutRequested());
                                context.go('/login');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'IbisSupply v1.0.0',
                          style: AppTheme.sans(
                              fontSize: 12,
                              color: const Color(0xFFD4D4D8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill tag ──────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const _Pill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTheme.sans(
              fontSize: 12, weight: FontWeight.w600, color: fg)),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.52,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTheme.sans(
              fontSize: 11,
              color: const Color(0xFF71717A),
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Eyebrow ───────────────────────────────────────────────────────────────────
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFA1A1AA),
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Menu row ──────────────────────────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool danger;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppTheme.error : AppTheme.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 16,
                  color: danger
                      ? AppTheme.error
                      : const Color(0xFF3F3F46)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTheme.sans(
                      fontSize: 14, weight: FontWeight.w500, color: fg)),
            ),
            if (value != null) ...[
              Text(value!,
                  style: AppTheme.sans(
                      fontSize: 12, color: const Color(0xFF71717A))),
              const SizedBox(width: 6),
            ],
            if (!danger)
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: Color(0xFFD4D4D8)),
          ],
        ),
      ),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5),
          indent: 16, endIndent: 16);
}

// ── Şifre değiştir dialog ─────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentCtrl, newCtrl, confirmCtrl;
  const _ChangePasswordDialog({
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final current = widget.currentCtrl.text;
    final newPw = widget.newCtrl.text;
    final confirm = widget.confirmCtrl.text;
    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Tüm alanları doldurun');
      return;
    }
    if (newPw != confirm) {
      setState(() => _error = 'Yeni şifreler eşleşmiyor');
      return;
    }
    if (newPw.length < 6) {
      setState(() => _error = 'Yeni şifre en az 6 karakter olmalı');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.create().put('/auth/password',
          data: {'currentPassword': current, 'newPassword': newPw});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Şifre başarıyla değiştirildi', style: AppTheme.sans()),
          backgroundColor: AppTheme.riskLow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.response?.data as String? ??
          'Şifre değiştirilemedi';
      setState(() { _loading = false; _error = msg; });
    } catch (_) {
      setState(() { _loading = false; _error = 'Bir hata oluştu'; });
    }
  }

  Widget _field(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: AppTheme.sans(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sans(fontSize: 13, color: const Color(0xFFD4D4D8)),
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3F3FE8), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      title: Row(
        children: [
          const Icon(LucideIcons.lock, size: 18, color: Color(0xFF3F3FE8)),
          const SizedBox(width: 8),
          Text('Şifre Değiştir',
              style: AppTheme.sans(fontSize: 16, weight: FontWeight.w600)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field('Mevcut şifre', widget.currentCtrl),
          const SizedBox(height: 10),
          _field('Yeni şifre', widget.newCtrl),
          const SizedBox(height: 10),
          _field('Yeni şifre (tekrar)', widget.confirmCtrl),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: AppTheme.sans(
                    fontSize: 12, color: AppTheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('İptal',
              style: AppTheme.sans(color: const Color(0xFF71717A))),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Kaydet', style: AppTheme.sans(weight: FontWeight.w600)),
        ),
      ],
    );
  }
}
