import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart' hide ShipmentEvent;
import '../model/shipment_model.dart';
import '../../../core/theme/app_theme.dart';

class ShipmentDetailScreen extends StatelessWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShipmentBloc()..add(LoadShipmentDetail(shipmentId)),
      child: _ShipmentDetailView(shipmentId: shipmentId),
    );
  }
}

class _ShipmentDetailView extends StatelessWidget {
  final String shipmentId;
  const _ShipmentDetailView({required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Sevkiyat Detayı')),
      body: BlocConsumer<ShipmentBloc, ShipmentState>(
        listener: (context, state) {
          if (state is ShipmentEventAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Güncellendi'), backgroundColor: AppTheme.success),
            );
          }
          if (state is ShipmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ShipmentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShipmentError) {
            return Center(child: Text(state.message));
          }

          ShipmentResponse? shipment;
          if (state is ShipmentDetailLoaded) shipment = state.shipment;
          if (state is ShipmentEventAdded) shipment = state.shipment;
          if (shipment == null) return const SizedBox();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _HeaderCard(shipment: shipment),
                const SizedBox(height: 12),
                _InfoCard(title: 'Güzergah', rows: [
                  ('Çıkış', shipment.fromLocation),
                  ('Varış', shipment.toLocation),
                  if (shipment.vehiclePlate != null) ('Plaka', shipment.vehiclePlate!),
                  ('Taşıyıcı', shipment.carrierName),
                ]),
                const SizedBox(height: 12),
                _InfoCard(title: 'Batch Bilgisi', rows: [
                  ('Ürün', shipment.productName),
                  ('Batch Kodu', shipment.batchCode),
                ]),
                const SizedBox(height: 12),
                _TimelineCard(events: shipment.events),
                const SizedBox(height: 12),
                if (shipment.status != 'DELIVERED' && shipment.status != 'FAILED')
                  _ActionButtons(shipment: shipment),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ShipmentResponse shipment;
  const _HeaderCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(shipment.status);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.local_shipping_rounded, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            shipment.shipmentCode,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold,
                fontSize: 15, color: AppTheme.primary),
          ),
          const SizedBox(height: 6),
          _StatusBadge(status: shipment.status),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING': return const Color(0xFF1565C0);
      case 'IN_TRANSIT': return const Color(0xFF6A1B9A);
      case 'DELIVERED': return const Color(0xFF2E7D32);
      case 'FAILED': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(row.$1, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(row.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final List<ShipmentEvent> events;
  const _TimelineCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Takip Geçmişi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text('Henüz olay yok', style: TextStyle(color: Colors.grey[400], fontSize: 13))
          else
            ...events.asMap().entries.map((entry) {
              final i = entry.key;
              final event = entry.value;
              final isLast = i == events.length - 1;
              return _TimelineItem(event: event, isLast: isLast);
            }),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ShipmentEvent event;
  final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.eventType);
    final icon = _eventIcon(event.eventType);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE8EEF4),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_eventLabel(event.eventType),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                  if (event.locationAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(event.locationAddress!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                  if (event.notes != null) ...[
                    const SizedBox(height: 2),
                    Text(event.notes!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                  if (event.temperature != null) ...[
                    const SizedBox(height: 2),
                    Text('${event.temperature}°C',
                        style: const TextStyle(color: Color(0xFFE65100), fontSize: 12)),
                  ],
                  const SizedBox(height: 4),
                  Text(_formatTime(event.eventTime),
                      style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'CREATED': return const Color(0xFF1565C0);
      case 'DEPARTED': return const Color(0xFF6A1B9A);
      case 'CHECKPOINT': return const Color(0xFF00838F);
      case 'TEMPERATURE_LOG': return const Color(0xFFE65100);
      case 'DELIVERED': return const Color(0xFF2E7D32);
      case 'INCIDENT': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'CREATED': return Icons.add_circle_outline;
      case 'DEPARTED': return Icons.local_shipping_outlined;
      case 'CHECKPOINT': return Icons.location_on_outlined;
      case 'TEMPERATURE_LOG': return Icons.thermostat_outlined;
      case 'DELIVERED': return Icons.check_circle_outline;
      case 'INCIDENT': return Icons.warning_amber_outlined;
      default: return Icons.circle_outlined;
    }
  }

  String _eventLabel(String type) {
    const labels = {
      'CREATED': 'Oluşturuldu',
      'DEPARTED': 'Yola Çıktı',
      'CHECKPOINT': 'Kontrol Noktası',
      'TEMPERATURE_LOG': 'Sıcaklık Kaydı',
      'DELIVERED': 'Teslim Edildi',
      'INCIDENT': 'Olay',
    };
    return labels[type] ?? type;
  }

  String _formatTime(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }
}

class _ActionButtons extends StatelessWidget {
  final ShipmentResponse shipment;
  const _ActionButtons({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İşlemler',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
          const SizedBox(height: 12),
          if (shipment.status == 'PENDING')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Yola Çıkar (DEPARTED)'),
                onPressed: () => context.read<ShipmentBloc>().add(AddShipmentEvent(
                      shipmentId: shipment.id,
                      eventType: 'DEPARTED',
                      locationAddress: shipment.fromLocation,
                      notes: 'Araç yola çıktı',
                    )),
              ),
            ),
          if (shipment.status == 'IN_TRANSIT') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Teslim Edildi'),
                onPressed: () => context.read<ShipmentBloc>().add(DeliverShipment(shipment.id)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Kontrol Noktası Ekle'),
                onPressed: () => _showAddEventDialog(context, shipment.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, String shipmentId) {
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kontrol Noktası'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: 'Konum'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Not'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              context.read<ShipmentBloc>().add(AddShipmentEvent(
                    shipmentId: shipmentId,
                    eventType: 'CHECKPOINT',
                    locationAddress: locCtrl.text,
                    notes: notesCtrl.text,
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
