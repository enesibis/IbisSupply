import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final fullName = authState is AuthAuthenticated ? authState.fullName : '';
    final orgName = authState is AuthAuthenticated ? authState.orgName : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('IbisSupply'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      radius: 28,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (orgName != null && orgName.isNotEmpty)
                            Text(orgName, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 4),
                          _RoleBadge(role: role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text('Hızlı Erişim', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Role-based quick actions grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _buildMenuItems(context, role),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, String role) {
    final items = <_MenuItem>[];

    // QR Tara — everyone
    items.add(_MenuItem(icon: Icons.qr_code_scanner, label: 'QR Tara', color: AppTheme.primary, onTap: () => context.push('/qr-public')));

    // Batch — PRODUCER, PROCESSOR, ADMIN
    if (['PRODUCER', 'PROCESSOR', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(icon: Icons.inventory_2_outlined, label: 'Batch Yönetimi', color: const Color(0xFF1565C0), onTap: () {}));
    }

    // Shipment — LOGISTICS, WAREHOUSE, ADMIN
    if (['LOGISTICS', 'WAREHOUSE', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(icon: Icons.local_shipping_outlined, label: 'Sevkiyat', color: const Color(0xFF6A1B9A), onTap: () {}));
    }

    // Quality — INSPECTOR, ADMIN
    if (['INSPECTOR', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(icon: Icons.verified_outlined, label: 'Kalite Kontrol', color: const Color(0xFFE65100), onTap: () {}));
    }

    // Alerts — all staff
    if (role != 'CUSTOMER') {
      items.add(_MenuItem(icon: Icons.notifications_outlined, label: 'Uyarılar', color: AppTheme.warning, onTap: () {}));
    }

    // Admin
    if (role == 'ADMIN') {
      items.add(_MenuItem(icon: Icons.admin_panel_settings_outlined, label: 'Yönetim', color: Colors.grey[700]!, onTap: () {}));
    }

    return items.map((item) => _DashboardCard(item: item)).toList();
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.color, required this.onTap});
}

class _DashboardCard extends StatelessWidget {
  final _MenuItem item;
  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 36, color: item.color),
              const SizedBox(height: 8),
              Text(item.label, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'ADMIN': AppTheme.primary,
      'PRODUCER': const Color(0xFF1565C0),
      'PROCESSOR': const Color(0xFF6A1B9A),
      'LOGISTICS': const Color(0xFFE65100),
      'WAREHOUSE': const Color(0xFF004D40),
      'INSPECTOR': const Color(0xFF880E4F),
      'RETAILER': const Color(0xFF33691E),
      'CUSTOMER': Colors.grey,
    };
    final color = colors[role] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(role, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
