import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1A33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Şifre Değiştir',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Mevcut Şifre', currentCtrl, true),
            const SizedBox(height: 12),
            _dialogField('Yeni Şifre', newCtrl, true),
            const SizedBox(height: 12),
            _dialogField('Yeni Şifre (Tekrar)', confirmCtrl, true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Şifreler eşleşmiyor'),
                    backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Şifre değiştirme yakında eklenecek'),
                  backgroundColor: Color(0xFF1976D2)));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Kaydet'),
          ),
        ],
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
