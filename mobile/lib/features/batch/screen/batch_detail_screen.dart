import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/batch_model.dart';

class BatchDetailScreen extends StatelessWidget {
  final BatchResponse batch;
  const BatchDetailScreen({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        title: const Text(
          'Batch Detayı',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.copy_outlined,
                color: Colors.white.withValues(alpha: 0.6)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: batch.batchCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Batch kodu kopyalandı'),
                  backgroundColor: const Color(0xFF1976D2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Kart
            _GlassCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: batch.qrCode,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    batch.batchCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF42A5F5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: batch.status),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Blockchain TX Hash — öne çıkan bölüm
            if (batch.blockchainTxHash != null)
              _BlockchainCard(txHash: batch.blockchainTxHash!, context: context)
            else
              _BlockchainPendingCard(),

            const SizedBox(height: 12),

            // Ürün bilgileri
            _InfoCard(
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF42A5F5),
              title: 'Ürün Bilgileri',
              rows: [
                ('Ürün Adı', batch.productName),
                ('Kategori', batch.productCategory),
                ('Miktar', '${batch.quantity} ${batch.unit}'),
                ('Menşei', batch.originLocation ?? '-'),
              ],
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFFFFB74D),
              title: 'Tarih Bilgileri',
              rows: [
                ('Üretim', _formatDate(batch.productionDate)),
                ('Son Kullanma', _formatDate(batch.expiryDate)),
                ('Oluşturulma', _formatDateTime(batch.createdAt)),
              ],
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.business_rounded,
              iconColor: const Color(0xFF66BB6A),
              title: 'Üretici Bilgileri',
              rows: [
                ('Üretici', batch.producerName),
                ('Organizasyon', batch.organizationName),
              ],
            ),

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

// ── Blockchain TX Hash kartı ──────────────────────────────────────────────────
class _BlockchainCard extends StatelessWidget {
  final String txHash;
  final BuildContext context;
  const _BlockchainCard({required this.txHash, required this.context});

  @override
  Widget build(BuildContext _) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2E1A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.link_rounded,
                        color: Color(0xFF66BB6A), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain\'e Yazıldı',
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Ethereum Hardhat Testnet • Chain 31337',
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF66BB6A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'TX Hash',
                style: TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      txHash,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: txHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('TX Hash kopyalandı'),
                          backgroundColor: const Color(0xFF2E7D32),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF66BB6A).withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: Color(0xFF66BB6A), size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Blockchain bekleniyor kartı ───────────────────────────────────────────────
class _BlockchainPendingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pending_rounded,
                    color: Colors.white.withValues(alpha: 0.3), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blockchain kaydı bekleniyor',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Seed verisi — TX hash yok',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 14),
              ...rows.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            row.$1,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
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

// ── Glass kart wrapper ────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
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
    'CREATED': Color(0xFF42A5F5),
    'IN_TRANSIT': Color(0xFFCE93D8),
    'IN_WAREHOUSE': Color(0xFF66BB6A),
    'SOLD': Color(0xFF4DB6AC),
    'RECALLED': Color(0xFFEF5350),
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
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
