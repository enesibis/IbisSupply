import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final fullName = authState is AuthAuthenticated ? authState.fullName : '';
    final orgName = authState is AuthAuthenticated ? authState.orgName : '';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Arka plan ─────────────────────────────────────────────
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

          // Üstte mavi ışık hâlesi
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF1565C0).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── İçerik ────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildHeader(
                            context, fullName, orgName, role),
                      ),
                    ),

                    // Menü grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel(text: 'Hızlı Erişim'),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.15,
                              children: _buildMenuItems(context, role),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Son aktiviteler
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SectionLabel(text: 'Son Aktiviteler'),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Tümü',
                                    style: TextStyle(
                                      color: const Color(0xFF42A5F5)
                                          .withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _ActivityCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String fullName, String? orgName, String role) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ),
              const SizedBox(width: 14),
              // İsim + org
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba, ${fullName.split(' ').first}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (orgName != null && orgName.isNotEmpty)
                      Text(
                        orgName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Rol badge + logout
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF1976D2)
                              .withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      labels[role] ?? role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    },
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, String role) {
    final items = <_MenuItem>[];

    items.add(_MenuItem(
      icon: Icons.qr_code_scanner_rounded,
      label: 'QR Tara',
      iconColor: const Color(0xFF42A5F5),
      glowColor: const Color(0xFF1565C0),
      onTap: () => context.push('/qr-public'),
    ));

    if (['PRODUCER', 'PROCESSOR', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.inventory_2_rounded,
        label: 'Batch Yönetimi',
        iconColor: const Color(0xFF66BB6A),
        glowColor: const Color(0xFF2E7D32),
        onTap: () => context.push('/batches'),
      ));
    }

    if (['PRODUCER', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.grass_rounded,
        label: 'Tarımsal Kayıtlar',
        iconColor: const Color(0xFF81C784),
        glowColor: const Color(0xFF1B5E20),
        onTap: () => context.push('/farm-records'),
      ));
    }

    if (['PRODUCER', 'LOGISTICS', 'WAREHOUSE', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.local_shipping_rounded,
        label: 'Sevkiyat',
        iconColor: const Color(0xFFCE93D8),
        glowColor: const Color(0xFF6A1B9A),
        onTap: () => context.push('/shipments'),
      ));
    }

    if (['INSPECTOR', 'ADMIN'].contains(role)) {
      items.add(_MenuItem(
        icon: Icons.verified_rounded,
        label: 'Kalite Kontrol',
        iconColor: const Color(0xFFFFB74D),
        glowColor: const Color(0xFFE65100),
        onTap: () => context.push('/quality-checks'),
      ));
    }

    if (role == 'CUSTOMER') {
      items.add(_MenuItem(
        icon: Icons.favorite_rounded,
        label: 'Ürünlerim',
        iconColor: const Color(0xFFEF9A9A),
        glowColor: const Color(0xFFC62828),
        onTap: () => context.push('/my-products'),
      ));
      items.add(_MenuItem(
        icon: Icons.report_problem_rounded,
        label: 'Şikayet Bildir',
        iconColor: const Color(0xFFFFB74D),
        glowColor: const Color(0xFFE65100),
        onTap: () => context.push('/complaint'),
      ));
    }

    if (role != 'CUSTOMER') {
      items.add(_MenuItem(
        icon: Icons.notifications_rounded,
        label: 'Uyarılar',
        iconColor: const Color(0xFFEF9A9A),
        glowColor: const Color(0xFFC62828),
        onTap: () => context.push('/alerts'),
      ));
    }

    if (role == 'ADMIN') {
      items.add(_MenuItem(
        icon: Icons.admin_panel_settings_rounded,
        label: 'Yönetim',
        iconColor: const Color(0xFF90A4AE),
        glowColor: const Color(0xFF263238),
        onTap: () => context.push('/admin/users'),
      ));
    }

    return items.map((item) => _GlassMenuCard(item: item)).toList();
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.45),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── MenuItem data ─────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color glowColor;
  final VoidCallback onTap;
  _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.glowColor,
    required this.onTap,
  });
}

// ── Glass menu card ───────────────────────────────────────────────────────────
class _GlassMenuCard extends StatelessWidget {
  final _MenuItem item;
  const _GlassMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İkon kutusu
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.glowColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: item.iconColor.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: item.glowColor.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Activity card ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activities = [
      (
        'Batch #2024001 oluşturuldu',
        'Domates - 500 kg',
        Icons.inventory_2_outlined,
        const Color(0xFF42A5F5),
        '2s önce'
      ),
      (
        'Sevkiyat #S-001 yola çıktı',
        'İstanbul → Ankara',
        Icons.local_shipping_outlined,
        const Color(0xFFCE93D8),
        '1s önce'
      ),
      (
        'Kalite kontrolü tamamlandı',
        'Batch #2024001 onaylandı',
        Icons.verified_outlined,
        const Color(0xFF66BB6A),
        '30dk önce'
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final i = entry.key;
              final (title, sub, icon, color, time) = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withValues(alpha: 0.2)),
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                sub,
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < activities.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                      indent: 14,
                      endIndent: 14,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
