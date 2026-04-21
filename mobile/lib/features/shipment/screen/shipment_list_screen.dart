import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart';
import '../model/shipment_model.dart';
import '../../../core/widgets/ibis_app_bar.dart';
import '../../../core/widgets/ibis_list_tile.dart';
import '../../../core/theme/ibis_colors.dart';
import 'shipment_create_screen.dart';
import 'shipment_detail_screen.dart';

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

class _ShipmentListView extends StatelessWidget {
  const _ShipmentListView();

  void _confirmDelete(BuildContext context, ShipmentResponse shipment) {
    final c = IbisColors.of(context);
    if (shipment.status != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sadece PENDING statüsündeki sevkiyatlar silinebilir'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sevkiyatı Sil',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('${shipment.productName} sevkiyatı kalıcı olarak silinecek. Emin misiniz?',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ShipmentBloc>().add(DeleteShipment(shipment.id));
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Sevkiyat Yönetimi',
        accentColor: const Color(0xFFCE93D8),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<ShipmentBloc>().add(LoadShipments()),
          ),
        ],
      ),
      floatingActionButton: IbisFab(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ShipmentCreateScreen()),
          );
          if (created == true && context.mounted) {
            context.read<ShipmentBloc>().add(LoadShipments());
          }
        },
        icon: Icons.add_rounded,
        label: 'Yeni Sevkiyat',
        colors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
      ),
      body: BlocConsumer<ShipmentBloc, ShipmentState>(
        listener: (context, state) {
          if (state is ShipmentDeleted) {
            context.read<ShipmentBloc>().add(LoadShipments());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sevkiyat silindi'),
              backgroundColor: Color(0xFF455A64),
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is ShipmentError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is ShipmentLoading) return const _LoadingView();
          if (state is ShipmentError) {
            return IbisErrorState(
              message: state.message,
              onRetry: () => context.read<ShipmentBloc>().add(LoadShipments()),
            );
          }
          if (state is ShipmentListLoaded) {
            if (state.shipments.isEmpty) {
              return const IbisEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Henüz sevkiyat yok',
                subtitle: 'Yeni bir sevkiyat oluşturmak için\nsağ alttaki butona bas.',
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
              itemCount: state.shipments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ShipmentCard(
                shipment: state.shipments[i],
                onDelete: () => _confirmDelete(context, state.shipments[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: c.isDark ? null : Colors.white,
          gradient: c.isDark
              ? LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.04 + _anim.value * 0.03),
                  Colors.white.withValues(alpha: 0.02),
                ])
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShipmentResponse shipment;
  final VoidCallback onDelete;
  const _ShipmentCard({required this.shipment, required this.onDelete});

  static const _statusColors = {
    'PENDING': Color(0xFF42A5F5),
    'IN_TRANSIT': Color(0xFFCE93D8),
    'DELIVERED': Color(0xFF66BB6A),
    'FAILED': Color(0xFFEF5350),
  };

  static const _statusLabels = {
    'PENDING': 'Bekliyor',
    'IN_TRANSIT': 'Yolda',
    'DELIVERED': 'Teslim Edildi',
    'FAILED': 'Başarısız',
  };

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final color = _statusColors[shipment.status] ?? const Color(0xFF42A5F5);

    return IbisListTile(
      accentColor: color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ShipmentDetailScreen(shipmentId: shipment.id)),
      ),
      icon: Icon(Icons.local_shipping_rounded, color: color, size: 22),
      title: Text(shipment.productName,
          style: TextStyle(color: c.text, fontWeight: FontWeight.w700,
              fontSize: 15, letterSpacing: -0.1)),
      subtitle: Row(
        children: [
          Text(shipment.fromLocation,
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.east_rounded, size: 11, color: c.textDisabled),
          ),
          Expanded(
            child: Text(shipment.toLocation,
                style: TextStyle(color: c.textMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      badge: Row(
        children: [
          IbisStatusBadge(
              label: _statusLabels[shipment.status] ?? shipment.status,
              color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(shipment.shipmentCode,
                style: TextStyle(color: c.textDisabled, fontSize: 10,
                    fontFamily: 'monospace', letterSpacing: 0.3),
                overflow: TextOverflow.ellipsis),
          ),
          if (shipment.status == 'PENDING') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.withValues(alpha: 0.7), size: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
