import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trace_bloc.dart';
import '../model/trace_model.dart';

class ProductTraceScreen extends StatelessWidget {
  final String batchCode;
  const ProductTraceScreen({super.key, required this.batchCode});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TraceBloc()..add(TraceByBatchCode(batchCode)),
      child: _TraceView(batchCode: batchCode),
    );
  }
}

class _TraceView extends StatelessWidget {
  final String batchCode;
  const _TraceView({required this.batchCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Ürün Geçmişi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<TraceBloc, TraceState>(
        builder: (context, state) {
          if (state is TraceLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is TraceError) {
            return _ErrorView(message: state.message, batchCode: batchCode);
          }
          if (state is TraceLoaded) {
            return _TraceContent(trace: state.trace);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String batchCode;
  const _ErrorView({required this.message, required this.batchCode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: Colors.redAccent, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Ürün Bulunamadı',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<TraceBloc>().add(TraceByBatchCode(batchCode)),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceContent extends StatelessWidget {
  final TraceResponse trace;
  const _TraceContent({required this.trace});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BatchCard(batch: trace.batch),
          const SizedBox(height: 16),
          if (trace.shipments.isEmpty)
            _EmptyShipments()
          else ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Sevkiyat Geçmişi',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...trace.shipments.map((s) => _ShipmentCard(shipment: s)),
          ],
          const SizedBox(height: 24),
          _VerifiedBadge(),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final BatchInfo batch;
  const _BatchCard({required this.batch});

  Color get _statusColor {
    switch (batch.status) {
      case 'CREATED': return const Color(0xFF42A5F5);
      case 'IN_TRANSIT': return const Color(0xFFFFB300);
      case 'DELIVERED': return const Color(0xFF66BB6A);
      case 'RECALLED': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (batch.status) {
      case 'CREATED': return 'Oluşturuldu';
      case 'IN_TRANSIT': return 'Taşımada';
      case 'DELIVERED': return 'Teslim Edildi';
      case 'RECALLED': return 'Geri Çağrıldı';
      default: return batch.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2857), Color(0xFF0B1A33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF42A5F5), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.productName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(batch.organizationName,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1A2F50)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.qr_code, label: 'Batch Kodu', value: batch.batchCode),
          _InfoRow(icon: Icons.category_outlined, label: 'Kategori', value: batch.productCategory),
          _InfoRow(icon: Icons.scale_outlined, label: 'Miktar', value: '${batch.quantity} ${batch.unit}'),
          _InfoRow(icon: Icons.calendar_today_outlined, label: 'Üretim Tarihi', value: batch.productionDate),
          _InfoRow(icon: Icons.event_outlined, label: 'Son Kullanma', value: batch.expiryDate),
          if (batch.originLocation != null && batch.originLocation!.isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, label: 'Köken', value: batch.originLocation!),
          _InfoRow(icon: Icons.person_outline, label: 'Üretici', value: batch.producerName),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF42A5F5), size: 16),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _EmptyShipments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: Colors.white.withValues(alpha: 0.3), size: 32),
          const SizedBox(width: 16),
          Text('Henüz sevkiyat kaydı yok',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShipmentInfo shipment;
  const _ShipmentCard({required this.shipment});

  Color get _statusColor {
    switch (shipment.status) {
      case 'PENDING': return const Color(0xFF42A5F5);
      case 'IN_TRANSIT': return const Color(0xFFFFB300);
      case 'DELIVERED': return const Color(0xFF66BB6A);
      case 'CANCELLED': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        iconColor: const Color(0xFF42A5F5),
        collapsedIconColor: Colors.white38,
        title: Row(
          children: [
            const Icon(Icons.local_shipping_rounded, color: Color(0xFF42A5F5), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shipment.shipmentCode,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${shipment.fromLocation} → ${shipment.toLocation}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(shipment.status,
                  style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        children: [
          if (shipment.carrierName.isNotEmpty)
            _InfoRow(icon: Icons.person_outline, label: 'Taşıyıcı', value: shipment.carrierName),
          if (shipment.vehiclePlate != null)
            _InfoRow(icon: Icons.directions_car_outlined, label: 'Araç', value: shipment.vehiclePlate!),
          if (shipment.events.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Olaylar',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...shipment.events.asMap().entries.map(
              (e) => _EventTile(event: e.value, isLast: e.key == shipment.events.length - 1),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventInfo event;
  final bool isLast;
  const _EventTile({required this.event, required this.isLast});

  IconData get _icon {
    switch (event.eventType) {
      case 'DEPARTED': return Icons.flight_takeoff_rounded;
      case 'CHECKPOINT': return Icons.pin_drop_rounded;
      case 'TEMPERATURE_LOG': return Icons.thermostat_rounded;
      case 'DELIVERED': return Icons.check_circle_rounded;
      case 'INCIDENT': return Icons.warning_amber_rounded;
      default: return Icons.circle_outlined;
    }
  }

  Color get _color {
    switch (event.eventType) {
      case 'DEPARTED': return const Color(0xFF42A5F5);
      case 'CHECKPOINT': return const Color(0xFFFFB300);
      case 'TEMPERATURE_LOG': return const Color(0xFF26C6DA);
      case 'DELIVERED': return const Color(0xFF66BB6A);
      case 'INCIDENT': return Colors.redAccent;
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.eventType,
                      style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (event.locationAddress != null)
                    Text(event.locationAddress!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  if (event.temperature != null)
                    Text('${event.temperature}°C  ${event.humidity != null ? '${event.humidity}%' : ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                  if (event.notes != null)
                    Text(event.notes!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(event.eventTime.length > 16 ? event.eventTime.substring(0, 16) : event.eventTime,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF66BB6A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IbisSupply Doğrulandı',
                    style: TextStyle(
                        color: Color(0xFF66BB6A), fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Bu ürünün tedarik zinciri kaydı doğrulanmıştır.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
