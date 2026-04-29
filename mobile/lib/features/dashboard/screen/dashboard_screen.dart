import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _batchCount;
  int? _shipmentCount;

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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final fullName =
        authState is AuthAuthenticated ? authState.fullName : '';
    final orgName =
        authState is AuthAuthenticated ? authState.orgName : null;
    final firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : 'Kullanıcı';
    final initial =
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNav(
        active: 0,
        onTap: (i) {
          switch (i) {
            case 1: context.push('/batches'); break;
            case 2: context.push('/qr-public'); break;
            case 3: context.push('/alerts'); break;
            case 4: context.push('/profile'); break;
          }
        },
      ),
      body: CustomScrollView(
        slivers: [
          // ── Large app bar ─────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            shadowColor: const Color(0xFF0A0A0B).withValues(alpha: 0.06),
            expandedHeight: 96,
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1,
              titlePadding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Merhaba,',
                            style: AppTheme.sans(
                              fontSize: 14,
                              weight: FontWeight.w400,
                              color: const Color(0xFFA1A1AA),
                            )),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                            text: '$firstName.',
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.accent,
                              letterSpacing: -0.44,
                            ),
                          ),
                        ])),
                      ],
                    ),
                  ),
                  // Bell with badge
                  _IconBtn(
                    icon: LucideIcons.bell,
                    badge: true,
                    onTap: () => context.push('/alerts'),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: LucideIcons.settings,
                    onTap: () => context.push('/profile'),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Role strip ───────────────────────────────────────────
                _RoleStrip(
                  initial: initial,
                  orgName: orgName ?? 'IbisSupply',
                  role: role,
                  batchCount: _batchCount,
                ),
                const SizedBox(height: 24),

                // ── Stats ────────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      eyebrow: 'TOPLAM',
                      value: _batchCount != null ? '$_batchCount' : '--',
                      sub: 'Batch',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      eyebrow: 'TOPLAM',
                      value: _shipmentCount != null
                          ? '$_shipmentCount'
                          : '--',
                      sub: 'Sevkiyat',
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                // ── Quick access ─────────────────────────────────────────
                _Eyebrow('HIZLI ERİŞİM'),
                const SizedBox(height: 12),
                _QuickGrid(role: role),
                const SizedBox(height: 28),

                // ── Activity feed ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Eyebrow('SON AKTİVİTELER'),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppTheme.accent,
                      ),
                      onPressed: () => context.push('/batches'),
                      child: Text('Tümü',
                          style: AppTheme.sans(
                              fontSize: 13,
                              weight: FontWeight.w500,
                              color: AppTheme.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActivityFeed(role: role),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Eyebrow label ─────────────────────────────────────────────────────────────
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFA1A1AA),
        letterSpacing: 1.32,
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback? onTap;

  const _IconBtn({required this.icon, this.badge = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.ink),
          ),
          if (badge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Role strip card ───────────────────────────────────────────────────────────
class _RoleStrip extends StatelessWidget {
  final String initial;
  final String orgName;
  final String role;
  final int? batchCount;

  const _RoleStrip({
    required this.initial,
    required this.orgName,
    required this.role,
    required this.batchCount,
  });

  static const _roleLabels = {
    'ADMIN': 'Admin', 'PRODUCER': 'Üretici', 'PROCESSOR': 'İşleyici',
    'LOGISTICS': 'Lojistik', 'WAREHOUSE': 'Depo', 'INSPECTOR': 'Denetçi',
    'RETAILER': 'Satıcı', 'CUSTOMER': 'Müşteri',
  };

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleLabels[role] ?? role;
    final batchLabel = batchCount != null ? '$batchCount aktif batch' : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A0A0A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orgName,
                    style: AppTheme.sans(
                        fontSize: 13,
                        weight: FontWeight.w600,
                        color: AppTheme.ink)),
                const SizedBox(height: 1),
                Text('$roleLabel · $batchLabel',
                    style: AppTheme.sans(
                        fontSize: 11,
                        color: const Color(0xFFA1A1AA))),
              ],
            ),
          ),
          // Aktif tag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEFE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.checkCircle2,
                    size: 11, color: AppTheme.accent),
                const SizedBox(width: 4),
                Text(
                  'Aktif',
                  style: AppTheme.sans(
                      fontSize: 11,
                      weight: FontWeight.w600,
                      color: AppTheme.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String eyebrow;
  final String value;
  final String sub;

  const _StatCard({
    required this.eyebrow,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A0A0A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: const Color(0xFFA1A1AA),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              color: AppTheme.ink,
              height: 1,
              letterSpacing: -0.72,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: AppTheme.sans(fontSize: 12, color: const Color(0xFF52525B)),
          ),
        ],
      ),
    );
  }
}

// ── Quick access grid ─────────────────────────────────────────────────────────
class _QuickGrid extends StatelessWidget {
  final String role;
  const _QuickGrid({required this.role});

  @override
  Widget build(BuildContext context) {
    final tiles = _buildTiles(context, role);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) => tiles[i],
    );
  }

  List<Widget> _buildTiles(BuildContext context, String role) {
    final items = <_TileData>[];
    items.add(_TileData(LucideIcons.qrCode, 'QR Tara',
        () => context.push('/qr-public')));
    if (['PRODUCER', 'PROCESSOR', 'ADMIN', 'RETAILER'].contains(role)) {
      items.add(_TileData(LucideIcons.package, 'Batch yönetimi',
          () => context.push('/batches')));
    }
    if (['PRODUCER', 'ADMIN'].contains(role)) {
      items.add(_TileData(LucideIcons.leaf, 'Tarımsal kayıt',
          () => context.push('/farm-records')));
    }
    if (['PRODUCER', 'PROCESSOR', 'LOGISTICS', 'WAREHOUSE', 'RETAILER', 'ADMIN']
        .contains(role)) {
      items.add(_TileData(LucideIcons.truck, 'Sevkiyat',
          () => context.push('/shipments')));
    }
    if (['INSPECTOR', 'ADMIN'].contains(role)) {
      items.add(_TileData(LucideIcons.shieldCheck, 'Kalite kontrol',
          () => context.push('/quality-checks')));
    }
    if (role == 'CUSTOMER') {
      items.add(_TileData(LucideIcons.heart, 'Ürünlerim',
          () => context.push('/my-products')));
      items.add(_TileData(LucideIcons.fileWarning, 'Şikayet bildir',
          () => context.push('/complaint')));
    }
    if (role != 'CUSTOMER') {
      items.add(_TileData(LucideIcons.bell, 'Uyarılar',
          () => context.push('/alerts')));
    }
    if (role == 'ADMIN') {
      items.add(_TileData(LucideIcons.userCog, 'Yönetim',
          () => context.push('/admin/users')));
    }
    items.add(_TileData(LucideIcons.sparkles, 'AI asistan',
        () => context.push('/chat')));

    return items
        .map((t) => _QuickTile(icon: t.icon, label: t.label, onTap: t.onTap))
        .toList();
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _TileData(this.icon, this.label, this.onTap);
}

class _QuickTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutQuart,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0A0A0A),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon box
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: AppTheme.ink),
              ),
              // Label
              Text(
                widget.label,
                style: AppTheme.sans(
                  fontSize: 12,
                  weight: FontWeight.w600,
                  color: AppTheme.ink,
                  height: 1.3,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Activity feed ─────────────────────────────────────────────────────────────
class _ActivityFeed extends StatefulWidget {
  final String role;
  const _ActivityFeed({required this.role});

  @override
  State<_ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<_ActivityFeed> {
  List<_ActivityItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.role == 'CUSTOMER') {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final dio = ApiClient.create();
      final items = <_ActivityItem>[];
      try {
        final bRes = await dio.get('/batches');
        for (final b in (bRes.data as List).take(2)) {
          items.add(_ActivityItem(
            title: '${b['productName']} batch\'i oluşturuldu',
            sub: '${b['batchCode']} · ${b['quantity']} ${b['unit']}',
            icon: LucideIcons.package,
            danger: false,
            time: DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now(),
          ));
        }
      } catch (_) {}
      try {
        final sRes = await dio.get('/shipments');
        for (final s in (sRes.data as List).take(2)) {
          items.add(_ActivityItem(
            title: '${s['productName']} sevkiyatı',
            sub: '${s['fromLocation']} → ${s['toLocation']}',
            icon: LucideIcons.truck,
            danger: false,
            time: DateTime.tryParse(s['createdAt'] ?? '') ?? DateTime.now(),
          ));
        }
      } catch (_) {}
      items.sort((a, b) => b.time.compareTo(a.time));
      if (mounted) {
        setState(() {
          _items = items.take(4).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _rel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'az önce';
    if (d.inMinutes < 60) return '${d.inMinutes}dk';
    if (d.inHours < 24) return '${d.inHours}s';
    return '${d.inDays}g';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.accent),
          ),
        ),
      );
    }

    // Demo items if API is empty
    final display = _items.isNotEmpty
        ? _items
        : _demoItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A0A0A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: display.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.danger
                            ? const Color(0xFFFBE8E8)
                            : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        size: 16,
                        color: item.danger
                            ? AppTheme.error
                            : const Color(0xFF52525B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTheme.sans(
                              fontSize: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.sub,
                            style: AppTheme.sans(
                              fontSize: 11,
                              color: const Color(0xFFA1A1AA),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _rel(item.time),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < display.length - 1)
                const Divider(
                    height: 1,
                    color: Color(0xFFF4F4F5),
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  static final _demoItems = [
    _ActivityItem(
      title: 'Organik çilek batch\'i oluşturuldu',
      sub: 'BTCH-202604081529-7360 · 300 kg',
      icon: LucideIcons.package,
      danger: false,
      time: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    _ActivityItem(
      title: 'Muğla → İstanbul sevkiyatı başladı',
      sub: 'SHIP-202604091332-9982',
      icon: LucideIcons.truck,
      danger: false,
      time: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    _ActivityItem(
      title: 'Soğuk zincir ihlali tespit edildi',
      sub: '9.5 °C ölçüldü · Risk: ORTA',
      icon: LucideIcons.alertTriangle,
      danger: true,
      time: DateTime.now().subtract(const Duration(minutes: 32)),
    ),
    _ActivityItem(
      title: 'Kalite kontrolü onaylandı',
      sub: 'QC-44218 · NFT sertifika hazırlandı',
      icon: LucideIcons.shieldCheck,
      danger: false,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
}

class _ActivityItem {
  final String title, sub;
  final IconData icon;
  final bool danger;
  final DateTime time;
  const _ActivityItem({
    required this.title,
    required this.sub,
    required this.icon,
    required this.danger,
    required this.time,
  });
}

// ── Bottom navigation ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int active;
  final void Function(int) onTap;
  const _BottomNav({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xDCFFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFE4E4E7), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: 'Ana sayfa',
                active: active == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: LucideIcons.package,
                label: 'Batch',
                active: active == 1,
                onTap: () => onTap(1),
              ),
              // Center QR button
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -4),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.ink,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.qrCode,
                            size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: LucideIcons.bell,
                label: 'Uyarılar',
                active: active == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: LucideIcons.user,
                label: 'Profil',
                active: active == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppTheme.ink : const Color(0xFFA1A1AA);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTheme.sans(
                  fontSize: 10,
                  weight: FontWeight.w500,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
