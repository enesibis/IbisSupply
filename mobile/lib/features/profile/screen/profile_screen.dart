import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/api/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthAuthenticated) return const SizedBox.shrink();

    final roleLabels = {
      'ADMIN': 'Admin',
      'PRODUCER': 'Üretici',
      'PROCESSOR': 'İşleyici',
      'LOGISTICS': 'Lojistik',
      'WAREHOUSE': 'Depo',
      'INSPECTOR': 'Denetçi',
      'RETAILER': 'Satıcı',
      'CUSTOMER': 'Müşteri',
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
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // İsim
            Text(state.fullName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            // Rol badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                roleLabels[state.role] ?? state.role,
                style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),

            // Bilgi kartı
            _infoCard([
              _infoRow(Icons.email_rounded, 'E-posta', state.email),
              if (state.orgName != null && state.orgName!.isNotEmpty)
                _infoRow(Icons.business_rounded, 'Kuruluş', state.orgName!),
              _infoRow(Icons.shield_rounded, 'Rol', roleLabels[state.role] ?? state.role),
            ]),
            const SizedBox(height: 16),

            // Eylemler kartı
            _actionCard([
              _actionRow(
                icon: Icons.lock_outline_rounded,
                label: 'Şifre Değiştir',
                color: const Color(0xFF42A5F5),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ]),
            const SizedBox(height: 16),

            // Çıkış yap
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
                  side: BorderSide(
                      color: const Color(0xFFEF9A9A).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text('IbisSupply v1.0.0',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(children: rows),
        ),
      ),
    );
  }

  Widget _actionCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.35)),
          const SizedBox(width: 12),
          Text('$label:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Colors.white.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        currentCtrl: currentCtrl,
        newCtrl: newCtrl,
        confirmCtrl: confirmCtrl,
      ),
    );
  }

  Widget _dialogField(String hint, TextEditingController ctrl, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

// ── Şifre değiştir dialog ─────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final TextEditingController confirmCtrl;

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
      final dio = ApiClient.create();
      await dio.put('/auth/password', data: {
        'currentPassword': current,
        'newPassword': newPw,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Şifre başarıyla değiştirildi'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?
          ?? e.response?.data as String?
          ?? 'Şifre değiştirilemedi';
      setState(() { _loading = false; _error = msg; });
    } catch (_) {
      setState(() { _loading = false; _error = 'Bir hata oluştu'; });
    }
  }

  Widget _field(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1A33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: const Row(children: [
        Icon(Icons.lock_outline_rounded, color: Color(0xFF42A5F5), size: 20),
        SizedBox(width: 8),
        Text('Şifre Değiştir',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
            Text(_error!,
                style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('İptal',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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
