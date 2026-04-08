import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart';
import '../model/shipment_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        title: const Text(
          'Sevkiyat Yönetimi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.6)),
            onPressed: () =>
                context.read<ShipmentBloc>().add(LoadShipments()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ShipmentCreateScreen()),
          );
          if (created == true && context.mounted) {
            context.read<ShipmentBloc>().add(LoadShipments());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Sevkiyat'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          if (state is ShipmentLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is ShipmentError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(state.message,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () =>
                          context.read<ShipmentBloc>().add(LoadShipments()),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF1976D2).withValues(alpha: 0.2),
                        foregroundColor: const Color(0xFF42A5F5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ShipmentListLoaded) {
            if (state.shipments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Text('Henüz sevkiyat yok',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Yeni sevkiyat oluşturmak için + butonuna bas',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 13)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.shipments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _ShipmentCard(shipment: state.shipments[i]),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShipmentResponse shipment;
  const _ShipmentCard({required this.shipment});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFF42A5F5);
      case 'IN_TRANSIT':
        return const Color(0xFFCE93D8);
      case 'DELIVERED':
        return const Color(0xFF66BB6A);
      case 'FAILED':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  static const _statusLabels = {
    'PENDING': 'Bekliyor',
    'IN_TRANSIT': 'Yolda',
    'DELIVERED': 'Teslim Edildi',
    'FAILED': 'Başarısız',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(shipment.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ShipmentDetailScreen(shipmentId: shipment.id)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.local_shipping_rounded,
                      color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.productName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shipment.shipmentCode,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${shipment.fromLocation} → ${shipment.toLocation}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          _statusLabels[shipment.status] ?? shipment.status,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
