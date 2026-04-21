import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/bloc/theme_cubit.dart';
import '../../../core/widgets/ibis_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthAuthenticated) return const SizedBox.shrink();

    final c = IbisColors.of(context);

    final roleLabels = {
      'ADMIN': 'Admin', 'PRODUCER': 'Üretici', 'PROCESSOR': 'İşleyici',
      'LOGISTICS': 'Lojistik', 'WAREHOUSE': 'Depo', 'INSPECTOR': 'Denetçi',
      'RETAILER': 'Satıcı', 'CUSTOMER': 'Müşteri',
    };

    final roleColors = {
      'ADMIN':     const Color(0xFF7C4DFF),
      'PRODUCER':  const Color(0xFF1976D2),
      'PROCESSOR': const Color(0xFF7B1FA2),
      'LOGISTICS': const Color(0xFFBF360C),
      'WAREHOUSE': const Color(0xFF004D40),
      'INSPECTOR': const Color(0xFF880E4F),
      'RETAILER':  const Color(0xFF33691E),
      'CUSTOMER':  const Color(0xFF616161),
    };

    final color = roleColors[state.role] ?? const Color(0xFF1976D2);
    final initials = state.fullName.isNotEmpty
        ? state.fullName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(title: 'Profil', accentColor: const Color(0xFF42A5F5)),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 20, 32),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Avatar
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4),
                      blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            Text(state.fullName,
                style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(roleLabels[state.role] ?? state.role,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),

            // Bilgi kartı
            _Card(
              children: [
                _InfoRow(icon: Icons.email_rounded, label: 'E-posta', value: state.email),
                if (state.orgName != null && state.orgName!.isNotEmpty)
                  _InfoRow(icon: Icons.business_rounded, label: 'Kuruluş', value: state.orgName!),
                _InfoRow(icon: Icons.shield_rounded, label: 'Rol',
                    value: roleLabels[state.role] ?? state.role),
              ],
            ),
            const SizedBox(height: 16),

            // Eylemler kartı
            _Card(
              children: [
                _ActionRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Şifre Değiştir',
                  color: const Color(0xFF42A5F5),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                Divider(height: 1, color: c.border, indent: 16, endIndent: 16),
                // Tema toggle
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (ctx, themeMode) {
                    final isDark = themeMode == ThemeMode.dark;
                    return _ActionRow(
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      label: isDark ? 'Koyu Mod' : 'Açık Mod',
                      color: isDark ? const Color(0xFFCE93D8) : const Color(0xFFFFB74D),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => ctx.read<ThemeCubit>().toggle(),
                        activeThumbColor: const Color(0xFFCE93D8),
                        inactiveThumbColor: const Color(0xFFFFB74D),
                        inactiveTrackColor: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                      ),
                      onTap: () => ctx.read<ThemeCubit>().toggle(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Çıkış
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Çıkış Yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF9A9A),
                  side: BorderSide(color: const Color(0xFFEF9A9A).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('IbisSupply v1.0.0',
                style: TextStyle(color: c.textDisabled, fontSize: 12)),
          ],
        ),
      ),
    );
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
}

// ── Card wrapper ───────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(children: children),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textMuted),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: c.textMuted, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: TextStyle(color: c.text, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Action row ─────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  const _ActionRow({
    required this.icon, required this.label,
    required this.color, required this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: c.text, fontSize: 14)),
            const Spacer(),
            trailing ?? Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: c.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ── Şifre değiştir dialog ─────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentCtrl, newCtrl, confirmCtrl;
  const _ChangePasswordDialog({
    required this.currentCtrl, required this.newCtrl, required this.confirmCtrl,
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
      final dio = ApiClient.create();
      await dio.put('/auth/password', data: {
        'currentPassword': current, 'newPassword': newPw,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Şifre başarıyla değiştirildi'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.response?.data as String? ?? 'Şifre değiştirilemedi';
      setState(() { _loading = false; _error = msg; });
    } catch (_) {
      setState(() { _loading = false; _error = 'Bir hata oluştu'; });
    }
  }

  Widget _field(String hint, TextEditingController ctrl) {
    final c = IbisColors.of(context);
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: TextStyle(color: c.text, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textDisabled, fontSize: 13),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return AlertDialog(
      backgroundColor: c.dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border),
      ),
      title: Row(children: [
        const Icon(Icons.lock_outline_rounded, color: Color(0xFF42A5F5), size: 20),
        const SizedBox(width: 8),
        Text('Şifre Değiştir',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field('Mevcut Şifre', widget.currentCtrl),
          const SizedBox(height: 12),
          _field('Yeni Şifre', widget.newCtrl),
          const SizedBox(height: 12),
          _field('Yeni Şifre (Tekrar)', widget.confirmCtrl),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('İptal', style: TextStyle(color: c.textMuted)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
