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
      body: CustomScrollView(
        slivers: [
          // Mavi gradient header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  context.go('/login');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              radius: 24,
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Merhaba, ${fullName.split(' ').first}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (orgName != null && orgName.isNotEmpty)
                                    Text(
                                      orgName,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _RoleBadge(role: role),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hızlı erişim başlığı
                  const Text(
                    'Hızlı Erişim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: _buildMenuItems(context, role),
                  ),

                  const SizedBox(height: 24),

                  // Son aktiviteler başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Son Aktiviteler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Tümü', style: TextStyle(color: AppTheme.primaryLight)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ActivityPlaceholder(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, String role) {
    final items = <_MenuItem>[];

    items.add(_MenuItem(
      icon: Icons.qr_code_scanner_rounded,
      label: 'QR Tara',
      gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
      onTap: () => context.push('/qr-public'),
    ));

    if (['PRODUCER', 'PROCESSOR', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.inventory_2_rounded,
        label: 'Batch Yönetimi',
        gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF43A047)]),
        onTap: () => context.push('/batches'),
      ));
    }

    if (['LOGISTICS', 'WAREHOUSE', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.local_shipping_rounded,
        label: 'Sevkiyat',
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF9C27B0)]),
        onTap: () => context.push('/shipments'),
      ));
    }

    if (['INSPECTOR', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.verified_rounded,
        label: 'Kalite Kontrol',
        gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF8F00)]),
        onTap: () {},
      ));
    }

    if (role != 'CUSTOMER') {
      items.add(_MenuItem(
        icon: Icons.notifications_rounded,
        label: 'Uyarılar',
        gradient: const LinearGradient(colors: [Color(0xFFC62828), Color(0xFFEF5350)]),
        onTap: () {},
      ));
    }

    if (role == 'ADMIN') {
      items.add(_MenuItem(
        icon: Icons.admin_panel_settings_rounded,
        label: 'Yönetim',
        gradient: const LinearGradient(colors: [Color(0xFF263238), Color(0xFF546E7A)]),
        onTap: () {},
      ));
    }

    return items.map((item) => _DashboardCard(item: item)).toList();
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.gradient, required this.onTap});
}

class _DashboardCard extends StatelessWidget {
  final _MenuItem item;
  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEF4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF0D1B2A),
                ),
              ),
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
    final labels = {
      'ADMIN': 'Admin',
      'PRODUCER': 'Üretici',
      'PROCESSOR': 'İşleyici',
      'LOGISTICS': 'Lojistik',
      'WAREHOUSE': 'Depo',
      'INSPECTOR': 'Denetçi',
      'RETAILER': 'Satıcı',
      'CUSTOMER': 'Müşteri',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        labels[role] ?? role,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActivityPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Column(
        children: List.generate(3, (i) {
          final items = [
            ('Batch #2024001 oluşturuldu', 'Domates - 500 kg', Icons.inventory_2_outlined, Color(0xFF1565C0)),
            ('Sevkiyat #S-001 yola çıktı', 'İstanbul → Ankara', Icons.local_shipping_outlined, Color(0xFF6A1B9A)),
            ('Kalite kontrolü tamamlandı', 'Batch #2024001 onaylandı', Icons.verified_outlined, Color(0xFF2E7D32)),
          ];
          final (title, sub, icon, color) = items[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: Text('2s önce', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ),
              if (i < 2) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}
