import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/farm_record_model.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/widgets/ibis_app_bar.dart';

class FarmDetailScreen extends StatelessWidget {
  final FarmRecordResponse record;
  const FarmDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final irrigationLabel = {
      'DRIP': 'Damla Sulama',
      'SPRINKLER': 'Yağmurlama',
      'FLOOD': 'Taşkın Sulama',
      'MANUAL': 'Manuel',
    }[record.irrigationType] ?? record.irrigationType ?? '-';

    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Tarımsal Kayıt Detayı',
        accentColor: const Color(0xFF66BB6A),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(c),
            const SizedBox(height: 16),

            _sectionCard(c, 'Tarla Bilgileri', Icons.location_on_rounded, const Color(0xFF42A5F5), [
              _row(c, 'Konum', record.fieldLocation ?? '-'),
              if (record.plantingDate != null) _row(c, 'Ekim Tarihi', _formatDate(record.plantingDate!)),
              if (record.harvestDate != null) _row(c, 'Hasat Tarihi', _formatDate(record.harvestDate!)),
            ]),
            const SizedBox(height: 12),

            _sectionCard(c, 'Sulama', Icons.water_drop_rounded, const Color(0xFF29B6F6), [
              _row(c, 'Yöntem', irrigationLabel),
              if (record.totalIrrigationHours != null)
                _row(c, 'Toplam Süre', '${record.totalIrrigationHours} saat'),
            ]),
            const SizedBox(height: 12),

            if (record.pesticides != null && record.pesticides!.isNotEmpty) ...[
              _sectionCard(c, 'Kullanılan İlaçlar', Icons.science_rounded, const Color(0xFFEF9A9A), [
                _multilineText(c, record.pesticides!),
              ]),
              const SizedBox(height: 12),
            ],

            if (record.fertilizers != null && record.fertilizers!.isNotEmpty) ...[
              _sectionCard(c, 'Kullanılan Gübreler', Icons.grass_rounded, const Color(0xFF81C784), [
                _multilineText(c, record.fertilizers!),
              ]),
              const SizedBox(height: 12),
            ],

            if (record.notes != null && record.notes!.isNotEmpty) ...[
              _sectionCard(c, 'Notlar', Icons.notes_rounded, const Color(0xFFFFCC80), [
                _multilineText(c, record.notes!),
              ]),
              const SizedBox(height: 12),
            ],

            _sectionCard(c, 'Blockchain', Icons.link_rounded, const Color(0xFF7C4DFF), [
              if (record.blockchainTxHash != null) ...[
                _row(c, 'Durum', 'On-chain ✓'),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: record.blockchainTxHash!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TX Hash kopyalandı')),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.blockchainTxHash!,
                            style: const TextStyle(
                                color: Color(0xFFB39DDB), fontSize: 11, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy_rounded, size: 14, color: const Color(0xFF7C4DFF).withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                ),
              ] else
                _row(c, 'Durum', 'Zincire yazılmadı'),
            ]),
            const SizedBox(height: 12),

            _sectionCard(c, 'Kayıt Bilgisi', Icons.info_outline_rounded, const Color(0xFF90A4AE), [
              _row(c, 'Üretici', record.producerName),
              _row(c, 'Oluşturulma', _formatDateTime(record.createdAt)),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(IbisColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.grass_rounded, color: Color(0xFF66BB6A), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.productName,
                    style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(record.batchCode,
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (record.blockchainTxHash != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.4)),
              ),
              child: const Text('On-chain',
                  style: TextStyle(color: Color(0xFF42A5F5), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard(IbisColors c, String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IbisColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:', style: TextStyle(color: c.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: c.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _multilineText(IbisColors c, String text) {
    return Text(text, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.6));
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    } catch (_) {
      return date;
    }
  }

  String _formatDateTime(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }
}
