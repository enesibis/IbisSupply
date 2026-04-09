import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart' hide ShipmentEvent;
import '../model/shipment_model.dart';

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

// ── AI Anomali Banner ─────────────────────────────────────────────────────────
class _AnomalyBanner extends StatelessWidget {
  final AnomalyResultLoaded result;
  const _AnomalyBanner({required this.result});

  Color get _color {
    switch (result.riskLevel) {
      case 'CRITICAL': return const Color(0xFFEF5350);
      case 'HIGH':     return const Color(0xFFFF8F00);
      case 'MEDIUM':   return const Color(0xFFFFD54F);
      default:         return const Color(0xFF66BB6A);
    }
  }

  Color get _bgColor {
    switch (result.riskLevel) {
      case 'CRITICAL': return const Color(0xFF4A0A0A);
      case 'HIGH':     return const Color(0xFF3E1F00);
      case 'MEDIUM':   return const Color(0xFF3E2F00);
      default:         return const Color(0xFF0D2E1A);
    }
  }

  IconData get _icon {
    switch (result.riskLevel) {
      case 'CRITICAL':
      case 'HIGH':   return Icons.warning_rounded;
      case 'MEDIUM': return Icons.info_rounded;
      default:       return Icons.check_circle_rounded;
    }
  }

  String get _title {
    switch (result.riskLevel) {
      case 'CRITICAL': return 'KRİTİK: Soğuk Zincir Anomalisi';
      case 'HIGH':     return 'Yüksek Risk Tespit Edildi';
      case 'MEDIUM':   return 'Dikkat: Sıcaklık Dalgalanması';
      default:         return 'Soğuk Zincir Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(_icon, color: _color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_title,
                      style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Risk: ${result.riskScore.toStringAsFixed(0)}/100',
                    style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ]),
              if (result.recommendedAction.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(result.recommendedAction,
                    style: TextStyle(color: _color.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail view ───────────────────────────────────────────────────────────────
class _ShipmentDetailView extends StatefulWidget {
  final String shipmentId;
  const _ShipmentDetailView({required this.shipmentId});

  @override
  State<_ShipmentDetailView> createState() => _ShipmentDetailViewState();
}

class _ShipmentDetailViewState extends State<_ShipmentDetailView> {
  ShipmentResponse? _shipment;
  AnomalyResultLoaded? _anomaly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        title: const Text('Sevkiyat Detayı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_shipment != null)
            IconButton(
              icon: Icon(Icons.analytics_outlined,
                  color: Colors.white.withValues(alpha: 0.7)),
              tooltip: 'AI Anomali Analizi',
              onPressed: () => context
                  .read<ShipmentBloc>()
                  .add(LoadAnomalyResult(widget.shipmentId)),
            ),
        ],
      ),
      body: BlocConsumer<ShipmentBloc, ShipmentState>(
        listener: (context, state) {
          if (state is ShipmentDetailLoaded) {
            setState(() => _shipment = state.shipment);
            context.read<ShipmentBloc>().add(LoadAnomalyResult(widget.shipmentId));
          }
          if (state is ShipmentEventAdded) {
            setState(() => _shipment = state.shipment);
            _snack('Güncellendi', color: const Color(0xFF2E7D32));
            context.read<ShipmentBloc>().add(LoadAnomalyResult(widget.shipmentId));
          }
          if (state is AnomalyResultLoaded) {
            setState(() => _anomaly = state);
          }
          if (state is ShipmentError) {
            _snack(state.message, color: Colors.redAccent);
          }
        },
        builder: (context, state) {
          if (state is ShipmentLoading && _shipment == null) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is ShipmentError && _shipment == null) {
            return Center(
              child: Text(state.message,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            );
          }

          final shipment = _shipment;
          if (shipment == null) return const SizedBox();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_anomaly != null) _AnomalyBanner(result: _anomaly!),

                _GlassCard(
                  child: Column(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _statusColor(shipment.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _statusColor(shipment.status).withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.local_shipping_rounded,
                          color: _statusColor(shipment.status), size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      shipment.shipmentCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF42A5F5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(status: shipment.status),
                  ]),
                ),

                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.route_rounded,
                  iconColor: const Color(0xFFCE93D8),
                  title: 'Güzergah',
                  rows: [
                    ('Çıkış', shipment.fromLocation),
                    ('Varış', shipment.toLocation),
                    if (shipment.vehiclePlate != null) ('Plaka', shipment.vehiclePlate!),
                    if (shipment.carrierName.isNotEmpty) ('Taşıyıcı', shipment.carrierName),
                  ],
                ),

                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF42A5F5),
                  title: 'Batch Bilgisi',
                  rows: [
                    ('Ürün', shipment.productName),
                    ('Batch Kodu', shipment.batchCode),
                  ],
                ),

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

  void _snack(String msg, {Color color = const Color(0xFF1976D2)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':    return const Color(0xFF42A5F5);
      case 'IN_TRANSIT': return const Color(0xFFCE93D8);
      case 'DELIVERED':  return const Color(0xFF66BB6A);
      case 'FAILED':     return const Color(0xFFEF5350);
      default:           return Colors.grey;
    }
  }
}

// ── Glass kart ────────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Info kartı ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: iconColor, size: 15),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: iconColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 12),
              ...rows.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(row.$1,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13)),
                        ),
                        Expanded(
                          child: Text(row.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  final List<ShipmentEvent> events;
  const _TimelineCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.timeline_rounded, color: Color(0xFF42A5F5), size: 15),
                const SizedBox(width: 8),
                const Text('Takip Geçmişi',
                    style: TextStyle(
                        color: Color(0xFF42A5F5),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 12),
              if (events.isEmpty)
                Text('Henüz olay yok',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3), fontSize: 13))
              else
                ...events.asMap().entries.map((e) =>
                    _TimelineItem(event: e.value, isLast: e.key == events.length - 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ShipmentEvent event;
  final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  Color _color(String type) {
    switch (type) {
      case 'CREATED':         return const Color(0xFF42A5F5);
      case 'DEPARTED':        return const Color(0xFFCE93D8);
      case 'CHECKPOINT':      return const Color(0xFF4DD0E1);
      case 'TEMPERATURE_LOG': return const Color(0xFFFFB74D);
      case 'DELIVERED':       return const Color(0xFF66BB6A);
      case 'INCIDENT':        return const Color(0xFFEF5350);
      default:                return Colors.grey;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'CREATED':         return Icons.add_circle_outline;
      case 'DEPARTED':        return Icons.local_shipping_outlined;
      case 'CHECKPOINT':      return Icons.location_on_outlined;
      case 'TEMPERATURE_LOG': return Icons.thermostat_outlined;
      case 'DELIVERED':       return Icons.check_circle_outline;
      case 'INCIDENT':        return Icons.warning_amber_outlined;
      default:                return Icons.circle_outlined;
    }
  }

  String _label(String type) {
    const labels = {
      'CREATED':         'Oluşturuldu',
      'DEPARTED':        'Yola Çıktı',
      'CHECKPOINT':      'Kontrol Noktası',
      'TEMPERATURE_LOG': 'Sıcaklık Kaydı',
      'DELIVERED':       'Teslim Edildi',
      'INCIDENT':        'Olay',
    };
    return labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(event.eventType);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(_icon(event.eventType), color: color, size: 15),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.07),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(event.eventType),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                  if (event.locationAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(event.locationAddress!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                  ],
                  if (event.temperature != null) ...[
                    const SizedBox(height: 2),
                    Text('${event.temperature}°C',
                        style: const TextStyle(
                            color: Color(0xFFFFB74D),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                  if (event.notes != null && event.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(event.notes!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                  const SizedBox(height: 3),
                  Text(_formatTime(event.eventTime),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

// ── Aksiyon butonları ─────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final ShipmentResponse shipment;
  const _ActionButtons({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.touch_app_rounded,
                    color: Colors.white.withValues(alpha: 0.4), size: 15),
                const SizedBox(width: 8),
                Text('İşlemler',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 14),

              if (shipment.status == 'PENDING')
                _DarkButton(
                  label: 'Yola Çıkar',
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFFCE93D8),
                  glowColor: const Color(0xFF6A1B9A),
                  onTap: () => context.read<ShipmentBloc>().add(AddShipmentEvent(
                        shipmentId: shipment.id,
                        eventType: 'DEPARTED',
                        locationAddress: shipment.fromLocation,
                        notes: 'Araç yola çıktı',
                      )),
                ),

              if (shipment.status == 'IN_TRANSIT') ...[
                _DarkButton(
                  label: 'Teslim Edildi',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF66BB6A),
                  glowColor: const Color(0xFF2E7D32),
                  onTap: () => context
                      .read<ShipmentBloc>()
                      .add(DeliverShipment(shipment.id)),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _OutlineButton(
                      label: 'Kontrol Noktası',
                      icon: Icons.add_location_alt_outlined,
                      color: const Color(0xFF4DD0E1),
                      onTap: () => _showCheckpointDialog(context, shipment.id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineButton(
                      label: 'Sıcaklık Kaydı',
                      icon: Icons.thermostat_outlined,
                      color: const Color(0xFFFFB74D),
                      onTap: () => _showTemperatureDialog(context, shipment.id),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _showTemperatureDialog(BuildContext context, String shipmentId) {
    final tempCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: 'Sıcaklık Kaydı',
        icon: Icons.thermostat_outlined,
        iconColor: const Color(0xFFFFB74D),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(tempCtrl, 'Sıcaklık (°C)',
              type: const TextInputType.numberWithOptions(decimal: true, signed: true)),
          const SizedBox(height: 12),
          _dialogField(locCtrl, 'Konum (opsiyonel)'),
          const SizedBox(height: 12),
          _dialogField(notesCtrl, 'Not (opsiyonel)'),
        ]),
        onConfirm: () {
          final temp = double.tryParse(tempCtrl.text.replaceAll(',', '.'));
          if (temp == null) return;
          context.read<ShipmentBloc>().add(AddShipmentEvent(
                shipmentId: shipmentId,
                eventType: 'TEMPERATURE_LOG',
                locationAddress: locCtrl.text.isEmpty ? null : locCtrl.text,
                notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                temperature: temp,
              ));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCheckpointDialog(BuildContext context, String shipmentId) {
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: 'Kontrol Noktası',
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFF4DD0E1),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(locCtrl, 'Konum'),
          const SizedBox(height: 12),
          _dialogField(notesCtrl, 'Not'),
        ]),
        onConfirm: () {
          context.read<ShipmentBloc>().add(AddShipmentEvent(
                shipmentId: shipmentId,
                eventType: 'CHECKPOINT',
                locationAddress: locCtrl.text,
                notes: notesCtrl.text,
              ));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ── Dark dialog ───────────────────────────────────────────────────────────────
class _DarkDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget content;
  final VoidCallback onConfirm;
  const _DarkDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1F3C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

// ── Dark button ───────────────────────────────────────────────────────────────
class _DarkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color glowColor;
  final VoidCallback onTap;
  const _DarkButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ── Outline button ────────────────────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'PENDING':    'Bekliyor',
    'IN_TRANSIT': 'Yolda',
    'DELIVERED':  'Teslim Edildi',
    'FAILED':     'Başarısız',
  };

  static const _colors = {
    'PENDING':    Color(0xFF42A5F5),
    'IN_TRANSIT': Color(0xFFCE93D8),
    'DELIVERED':  Color(0xFF66BB6A),
    'FAILED':     Color(0xFFEF5350),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
