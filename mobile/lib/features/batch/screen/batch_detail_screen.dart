import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/batch_model.dart';
import '../../../core/theme/app_theme.dart';

class BatchDetailScreen extends StatelessWidget {
  final BatchResponse batch;
  const BatchDetailScreen({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Batch Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: batch.batchCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Batch kodu kopyalandı')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Kodu
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EEF4)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  QrImageView(
                    data: batch.qrCode,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    batch.batchCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: batch.status),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Ürün bilgileri
            _InfoCard(title: 'Ürün Bilgileri', rows: [
              ('Ürün Adı', batch.productName),
              ('Kategori', batch.productCategory),
              ('Miktar', '${batch.quantity} ${batch.unit}'),
              ('Menşei', batch.originLocation ?? '-'),
            ]),

            const SizedBox(height: 12),

            // Tarih bilgileri
            _InfoCard(title: 'Tarih Bilgileri', rows: [
              ('Üretim Tarihi', _formatDate(batch.productionDate)),
              ('Son Kullanma', _formatDate(batch.expiryDate)),
              ('Oluşturulma', _formatDateTime(batch.createdAt)),
            ]),

            const SizedBox(height: 12),

            // Üretici bilgileri
            _InfoCard(title: 'Üretici Bilgileri', rows: [
              ('Üretici', batch.producerName),
              ('Organizasyon', batch.organizationName),
            ]),

            if (batch.blockchainTxHash != null) ...[
              const SizedBox(height: 12),
              _InfoCard(title: 'Blockchain', rows: [
                ('TX Hash', batch.blockchainTxHash!),
              ]),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
      return '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(row.$1,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'CREATED': 'Oluşturuldu',
    'IN_TRANSIT': 'Taşımada',
    'IN_WAREHOUSE': 'Depoda',
    'SOLD': 'Satıldı',
    'RECALLED': 'Geri Çağrıldı',
  };

  static const _colors = {
    'CREATED': Color(0xFF1565C0),
    'IN_TRANSIT': Color(0xFF6A1B9A),
    'IN_WAREHOUSE': Color(0xFF2E7D32),
    'SOLD': Color(0xFF00695C),
    'RECALLED': Color(0xFFC62828),
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
