import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/shipment_bloc.dart';
import '../model/shipment_model.dart';
import 'shipment_create_screen.dart';
import 'shipment_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent  = Color(0xFF3F3FE8);
const _ink900  = Color(0xFF0A0A0B);
const _ink500  = Color(0xFF71717A);
const _ink400  = Color(0xFFA1A1AA);
const _ink300  = Color(0xFFD4D4D8);
const _line200 = Color(0xFFE4E4E7);
const _line100 = Color(0xFFF4F4F5);

const _kFilters = ['Tümü', 'Bekliyor', 'Yolda', 'Teslim', 'Başarısız'];

class ShipmentListScreen extends StatelessWidget {
  const ShipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShipmentBloc()..add(LoadShipments()),
      child: const _ShipmentListView(),
    );
  }
}

class _ShipmentListView extends StatefulWidget {
  const _ShipmentListView();
  @override
  State<_ShipmentListView> createState() => _ShipmentListViewState();
}

class _ShipmentListViewState extends State<_ShipmentListView> {
  int _filterIndex = 0;

  List<ShipmentResponse> _applyFilter(List<ShipmentResponse> all) {
    switch (_filterIndex) {
      case 1: return all.where((s) => s.status == 'PENDING').toList();
      case 2: return all.where((s) => s.status == 'IN_TRANSIT').toList();
      case 3: return all.where((s) => s.status == 'DELIVERED').toList();
      case 4: return all.where((s) => s.status == 'FAILED').toList();
      default: return all;
    }
  }

  void _confirmDelete(BuildContext context, ShipmentResponse shipment) {
    if (shipment.status != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sadece PENDING statüsündeki sevkiyatlar silinebilir',
            style: AppTheme.sans(color: Colors.white)),
        backgroundColor: const Color(0xFFB45309),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sevkiyatı Sil',
            style: AppTheme.sans(fontSize: 16, weight: FontWeight.w600)),
        content: Text(
          '${shipment.productName} sevkiyatı kalıcı olarak silinecek. Emin misiniz?',
          style: AppTheme.sans(fontSize: 14, color: _ink500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTheme.sans(color: _ink400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ShipmentBloc>().add(DeleteShipment(shipment.id));
            },
            child: Text('Sil', style: AppTheme.sans(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<ShipmentBloc, ShipmentState>(
        listener: (context, state) {
          if (state is ShipmentDeleted) {
            context.read<ShipmentBloc>().add(LoadShipments());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Sevkiyat silindi', style: AppTheme.sans()),
              backgroundColor: _ink900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
          if (state is ShipmentError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: AppTheme.sans()),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
        builder: (context, state) {
          final allShipments = state is ShipmentListLoaded ? state.shipments : <ShipmentResponse>[];
          final shipments = _applyFilter(allShipments);

          return CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────
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
                    'Sevkiyatlar',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: _ink900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                    color: _ink900,
                    onPressed: () => context.read<ShipmentBloc>().add(LoadShipments()),
                  ),
                  Builder(builder: (ctx) {
                    final authState = ctx.watch<AuthBloc>().state;
                    final role = authState is AuthAuthenticated ? authState.role : '';
                    final canCreate = role == 'LOGISTICS' || role == 'ADMIN';
                    if (!canCreate) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(LucideIcons.plus, size: 20),
                      color: _ink900,
                      onPressed: () async {
                        final created = await Navigator.push<bool>(
                          ctx,
                          MaterialPageRoute(builder: (_) => const ShipmentCreateScreen()),
                        );
                        if (created == true && ctx.mounted) {
                          ctx.read<ShipmentBloc>().add(LoadShipments());
                        }
                      },
                    );
                  }),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _line200),
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    itemCount: _kFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final active = i == _filterIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: active ? _ink900 : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? _ink900 : _line200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _kFilters[i],
                              style: AppTheme.sans(
                                fontSize: 12,
                                weight: FontWeight.w500,
                                color: active ? Colors.white : const Color(0xFF3F3F46),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────
              if (state is ShipmentLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: _ShimmerCard(),
                      ),
                      childCount: 5,
                    ),
                  ),
                )
              else if (state is ShipmentError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            size: 32, color: Color(0xFFB91C1C)),
                        const SizedBox(height: 12),
                        Text(state.message, style: AppTheme.sans(fontSize: 14)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.read<ShipmentBloc>().add(LoadShipments()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                                color: _ink900, borderRadius: BorderRadius.circular(10)),
                            child: Text('Tekrar dene',
                                style: AppTheme.sans(
                                    color: Colors.white, weight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (shipments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: _line100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.truck,
                              size: 24, color: _ink400),
                        ),
                        const SizedBox(height: 16),
                        Text('Sevkiyat bulunamadı',
                            style: AppTheme.sans(
                                fontSize: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          _filterIndex == 0
                              ? 'Yeni sevkiyat oluşturmak için + ikonuna bas'
                              : 'Farklı bir filtre deneyin',
                          style: AppTheme.sans(fontSize: 13, color: _ink500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ShipmentCard(
                          shipment: shipments[i],
                          onDelete: () => _confirmDelete(ctx, shipments[i]),
                        ),
                      ),
                      childCount: shipments.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shimmer card ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: 94,
        decoration: BoxDecoration(
          color: Color.lerp(_line100, Colors.white, _anim.value),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line200),
        ),
      ),
    );
  }
}

// ── Shipment card ─────────────────────────────────────────────────────────────
class _ShipmentCard extends StatelessWidget {
  final ShipmentResponse shipment;
  final VoidCallback onDelete;
  const _ShipmentCard({required this.shipment, required this.onDelete});

  String get _tagLabel {
    switch (shipment.status) {
      case 'IN_TRANSIT': return 'Yolda';
      case 'DELIVERED':  return 'Teslim';
      case 'FAILED':     return 'Başarısız';
      default:           return 'Bekliyor';
    }
  }

  Color get _tagFg {
    switch (shipment.status) {
      case 'IN_TRANSIT': return const Color(0xFFB45309);
      case 'DELIVERED':  return const Color(0xFF0F7A4B);
      case 'FAILED':     return const Color(0xFFB91C1C);
      default:           return _accent;
    }
  }

  Color get _tagBg {
    switch (shipment.status) {
      case 'IN_TRANSIT': return const Color(0xFFFBF1E1);
      case 'DELIVERED':  return const Color(0xFFE6F4EE);
      case 'FAILED':     return const Color(0xFFFEECEC);
      default:           return const Color(0xFFEEEEFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ShipmentDetailScreen(shipmentId: shipment.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.productName,
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: _ink900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(LucideIcons.mapPin, size: 11, color: _ink400),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            shipment.fromLocation,
                            style: AppTheme.sans(fontSize: 12, color: _ink500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: const Icon(LucideIcons.arrowRight,
                              size: 11, color: _ink300),
                        ),
                        Flexible(
                          child: Text(
                            shipment.toLocation,
                            style: AppTheme.sans(fontSize: 12, color: _ink500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tagBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_tagLabel,
                      style: AppTheme.sans(
                          fontSize: 11,
                          weight: FontWeight.w600,
                          color: _tagFg)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: _line100),
            const SizedBox(height: 10),
            // Footer row
            Row(children: [
              Expanded(
                child: Text(
                  shipment.shipmentCode,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: _ink400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (shipment.status == 'PENDING')
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(LucideIcons.trash2,
                      size: 14, color: _ink300),
                )
              else
                const Icon(LucideIcons.chevronRight, size: 16, color: _ink300),
            ]),
          ],
        ),
      ),
    );
  }
}
