import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/ibis_colors.dart';

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
    final c = IbisColors.of(context);
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final fullName = authState is AuthAuthenticated ? authState.fullName : '';
    final orgName = authState is AuthAuthenticated ? authState.orgName : '';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Düz zemin
          Container(color: c.pageBg),

          // İçerik
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildHeader(context, c, fullName, orgName, role),
                      ),
                    ),
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
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.05,
                              children: _buildMenuItems(context, c, role),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                                    style: TextStyle(color: c.accent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _ActivityCard(role: role),
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

  Widget _buildHeader(BuildContext context, IbisColors c, String fullName, String? orgName, String role) {
    final labels = {
      'ADMIN': 'Admin', 'PRODUCER': 'Üretici', 'PROCESSOR': 'İşleyici',
      'LOGISTICS': 'Lojistik', 'WAREHOUSE': 'Depo', 'INSPECTOR': 'Denetçi',
      'RETAILER': 'Satıcı', 'CUSTOMER': 'Müşteri',
    };

    Widget content = Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, ${fullName.split(' ').first}',
                style: TextStyle(
                    color: c.text, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (orgName != null && orgName.isNotEmpty)
                Text(orgName,
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.accentLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                labels[role] ?? role,
                style: TextStyle(
                  color: c.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                context.read<AuthBloc>().add(LogoutRequested());
                context.go('/login');
              },
              child: Icon(Icons.logout_rounded, color: c.textMuted, size: 18),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 1),
      ),
      child: content,
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, IbisColors c, String role) {
    final items = <_MenuItem>[];

    items.add(_MenuItem(icon: Icons.qr_code_scanner_rounded, label: 'QR Tara',
        iconColor: const Color(0xFF2E6840), glowColor: const Color(0xFF2E6840),
        onTap: () => context.push('/qr-public')));

    if (['PRODUCER', 'PROCESSOR', 'ADMIN'].contains(role))
      items.add(_MenuItem(icon: Icons.inventory_2_rounded, label: 'Batch Yönetimi',
          iconColor: const Color(0xFF66BB6A), glowColor: const Color(0xFF2E7D32),
          onTap: () => context.push('/batches')));

    if (['PRODUCER', 'ADMIN'].contains(role))
      items.add(_MenuItem(icon: Icons.grass_rounded, label: 'Tarımsal Kayıtlar',
          iconColor: const Color(0xFF81C784), glowColor: const Color(0xFF1B5E20),
          onTap: () => context.push('/farm-records')));

    if (['PRODUCER', 'PROCESSOR', 'LOGISTICS', 'WAREHOUSE', 'RETAILER', 'ADMIN'].contains(role))
      items.add(_MenuItem(icon: Icons.local_shipping_rounded, label: 'Sevkiyat',
          iconColor: const Color(0xFFCE93D8), glowColor: const Color(0xFF6A1B9A),
          onTap: () => context.push('/shipments')));

    if (['INSPECTOR', 'ADMIN'].contains(role))
      items.add(_MenuItem(icon: Icons.verified_rounded, label: 'Kalite Kontrol',
          iconColor: const Color(0xFFFFB74D), glowColor: const Color(0xFFE65100),
          onTap: () => context.push('/quality-checks')));

    if (['RETAILER'].contains(role))
      items.add(_MenuItem(icon: Icons.inventory_2_outlined, label: 'Batch Görüntüle',
          iconColor: const Color(0xFF4DB6AC), glowColor: const Color(0xFF00695C),
          onTap: () => context.push('/batches')));

    if (role == 'CUSTOMER') {
      items.add(_MenuItem(icon: Icons.favorite_rounded, label: 'Ürünlerim',
          iconColor: const Color(0xFFEF9A9A), glowColor: const Color(0xFFC62828),
          onTap: () => context.push('/my-products')));
      items.add(_MenuItem(icon: Icons.report_problem_rounded, label: 'Şikayet Bildir',
          iconColor: const Color(0xFFFFB74D), glowColor: const Color(0xFFE65100),
          onTap: () => context.push('/complaint')));
    }

    if (role != 'CUSTOMER')
      items.add(_MenuItem(icon: Icons.notifications_rounded, label: 'Uyarılar',
          iconColor: const Color(0xFFEF9A9A), glowColor: const Color(0xFFC62828),
          onTap: () => context.push('/alerts')));

    if (role == 'ADMIN')
      items.add(_MenuItem(icon: Icons.admin_panel_settings_rounded, label: 'Yönetim',
          iconColor: const Color(0xFF90A4AE), glowColor: const Color(0xFF263238),
          onTap: () => context.push('/admin/users')));

    items.add(_MenuItem(icon: Icons.auto_awesome_rounded, label: 'AI Asistan',
        iconColor: const Color(0xFFCE93D8), glowColor: const Color(0xFF6A1B9A),
        onTap: () => context.push('/chat')));

    return items.map((item) => _MenuCard(item: item)).toList();
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
        color: IbisColors.of(context).textMuted,
        letterSpacing: 0.3,
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
    required this.icon, required this.label, required this.iconColor,
    required this.glowColor, required this.onTap,
  });
}

// ── Menu card (dark/light aware) ──────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); item.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.iconColor.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Hairline accent çizgisi — gradient yok
                  Container(
                    width: 20,
                    height: 2,
                    color: item.iconColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Activity card ─────────────────────────────────────────────────────────────
class _ActivityItem {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final DateTime time;
  const _ActivityItem({
    required this.title, required this.subtitle,
    required this.icon, required this.color, required this.time,
  });
}

class _ActivityCard extends StatefulWidget {
  final String role;
  const _ActivityCard({required this.role});

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  List<_ActivityItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.role == 'CUSTOMER') {
      setState(() => _loading = false);
      return;
    }
    try {
      final dio = ApiClient.create();
      final items = <_ActivityItem>[];
      try {
        final bRes = await dio.get('/batches');
        for (final b in (bRes.data as List).take(3)) {
          items.add(_ActivityItem(
            title: '${b['productName']} batch\'i oluşturuldu',
            subtitle: '${b['batchCode']} · ${b['quantity']} ${b['unit']}',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF2E6840),
            time: DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now(),
          ));
        }
      } catch (_) {}
      try {
        final sRes = await dio.get('/shipments');
        for (final s in (sRes.data as List).take(3)) {
          items.add(_ActivityItem(
            title: '${s['productName']} sevkiyatı',
            subtitle: '${s['fromLocation']} → ${s['toLocation']}',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFFCE93D8),
            time: DateTime.tryParse(s['createdAt'] ?? '') ?? DateTime.now(),
          ));
        }
      } catch (_) {}
      items.sort((a, b) => b.time.compareTo(a.time));
      if (mounted) setState(() { _items = items.take(5).toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}s önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${t.day}.${t.month}.${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);

    if (_loading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: c.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: const Center(
          child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E6840))),
        ),
      );
    }

    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: Text('Henüz aktivite yok',
              style: TextStyle(color: c.textMuted, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: _items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: item.color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(item.icon, color: item.color, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: TextStyle(
                                  color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text(item.subtitle,
                              style: TextStyle(color: c.textMuted, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_relativeTime(item.time),
                        style: TextStyle(color: c.textDisabled, fontSize: 11)),
                  ],
                ),
              ),
              if (i < _items.length - 1)
                Divider(height: 1, color: c.border, indent: 14, endIndent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
}
