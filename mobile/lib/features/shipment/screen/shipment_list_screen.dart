import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart';
import '../model/shipment_model.dart';
import '../../../core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sevkiyat Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ShipmentBloc>().add(LoadShipments()),
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
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          if (state is ShipmentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShipmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.message, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ShipmentBloc>().add(LoadShipments()),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          if (state is ShipmentListLoaded) {
            if (state.shipments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Henüz sevkiyat yok', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Yeni sevkiyat oluşturmak için + butonuna bas',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.shipments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ShipmentCard(shipment: state.shipments[i]),
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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(shipment.status);
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipmentId: shipment.id)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shipment.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(shipment.shipmentCode,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.arrow_forward, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${shipment.fromLocation} → ${shipment.toLocation}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: shipment.status),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return const Color(0xFF1565C0);
      case 'IN_TRANSIT': return const Color(0xFF6A1B9A);
      case 'DELIVERED': return const Color(0xFF2E7D32);
      case 'FAILED': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'PENDING': 'Bekliyor',
    'IN_TRANSIT': 'Yolda',
    'DELIVERED': 'Teslim Edildi',
    'FAILED': 'Başarısız',
  };

  static const _colors = {
    'PENDING': Color(0xFF1565C0),
    'IN_TRANSIT': Color(0xFF6A1B9A),
    'DELIVERED': Color(0xFF2E7D32),
    'FAILED': Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
