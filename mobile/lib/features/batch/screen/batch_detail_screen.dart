import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/widgets/ibis_app_bar.dart';
import '../model/batch_model.dart';

class BatchDetailScreen extends StatefulWidget {
  final BatchResponse batch;
  const BatchDetailScreen({super.key, required this.batch});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  Map<String, dynamic>? _cert;
  bool _certLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    try {
      final dio = ApiClient.create();
      final res = await dio.get('/batches/code/${widget.batch.batchCode}/certificate');
      if (mounted) setState(() { _cert = res.data; _certLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _certLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Batch Detayı',
        accentColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_outlined, color: Colors.white.withValues(alpha: 0.7)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: batch.batchCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Batch kodu kopyalandı'),
                  backgroundColor: const Color(0xFF1976D2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 32),
        child: Column(
          children: [
            _QrCard(c: c, batch: batch),
            const SizedBox(height: 12),

            if (batch.blockchainTxHash != null)
              _BlockchainCard(txHash: batch.blockchainTxHash!, outerContext: context)
            else
              _BlockchainPendingCard(c: c),

            const SizedBox(height: 12),
            _CertificateCard(
              loading: _certLoading,
              cert: _cert,
              batchCode: batch.batchCode,
              productName: batch.productName,
              c: c,
            ),

            const SizedBox(height: 12),
            _InfoCard(
              c: c,
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
              c: c,
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
              c: c,
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
    } catch (_) { return date; }
  }

  String _formatDateTime(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return dt; }
  }
}

class _QrCard extends StatelessWidget {
  final IbisColors c;
  final BatchResponse batch;
  const _QrCard({required this.c, required this.batch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16, offset: const Offset(0, 4))],
      ),
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
    );
  }
}

// ── NFT Sertifika kartı ───────────────────────────────────────────────────────
class _CertificateCard extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? cert;
  final String batchCode;
  final String productName;
  final IbisColors c;

  const _CertificateCard({
    required this.loading, required this.cert,
    required this.batchCode, required this.productName, required this.c,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD54F))),
            const SizedBox(width: 14),
            Text('Sertifika kontrol ediliyor...', style: TextStyle(color: c.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    final hasCert = cert != null && cert!['exists'] == true;

    if (!hasCert) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.chipBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.workspace_premium_outlined, color: c.textDisabled, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NFT Sertifikası Yok', style: TextStyle(color: c.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                Text('Kalite kontrolü geçildiğinde mint edilir', style: TextStyle(color: c.textDisabled, fontSize: 11)),
              ],
            ),
          ],
        ),
      );
    }

    // Sertifika mevcut — altın gradyan her temada aynı kalır
    final tokenId = cert!['tokenId'] ?? '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A2000).withValues(alpha: 0.9),
            const Color(0xFF1A0E00).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFB300).withValues(alpha: 0.15),
              blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NFT Kalite Sertifikası',
                        style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('ERC-721 • IbisSupply Certificate',
                        style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.4)),
                ),
                child: const Text('ONAYLANMIŞ',
                    style: TextStyle(color: Color(0xFF66BB6A), fontSize: 10,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: const Color(0xFFFFD54F).withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _CertRow(label: 'Token ID', value: '#$tokenId')),
              Expanded(child: _CertRow(label: 'Tür', value: 'QUALITY_PASS')),
            ],
          ),
          const SizedBox(height: 8),
          _CertRow(label: 'Ürün', value: productName),
          const SizedBox(height: 8),
          _CertRow(label: 'Batch', value: batchCode, mono: true),
        ],
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _CertRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
                fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12,
                fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Blockchain TX Hash kartı ──────────────────────────────────────────────────
class _BlockchainCard extends StatelessWidget {
  final String txHash;
  final BuildContext outerContext;
  const _BlockchainCard({required this.txHash, required this.outerContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2E1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.link_rounded, color: Color(0xFF66BB6A), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Blockchain'e Yazıldı",
                      style: TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Ethereum Hardhat Testnet • Chain 31337',
                      style: TextStyle(color: Color(0xFF66BB6A), fontSize: 11)),
                ],
              ),
              const Spacer(),
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF66BB6A), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('TX Hash',
              style: TextStyle(color: Color(0xFF66BB6A), fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(txHash,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11, fontFamily: 'monospace', letterSpacing: 0.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: txHash));
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(
                      content: const Text('TX Hash kopyalandı'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Color(0xFF66BB6A), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlockchainPendingCard extends StatelessWidget {
  final IbisColors c;
  const _BlockchainPendingCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: Icon(Icons.pending_rounded, color: c.textDisabled, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blockchain kaydı bekleniyor',
                  style: TextStyle(color: c.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('Seed verisi — TX hash yok',
                  style: TextStyle(color: c.textDisabled, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info kartı ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IbisColors c;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({
    required this.c, required this.icon, required this.iconColor,
    required this.title, required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(color: iconColor, fontWeight: FontWeight.w600,
                      fontSize: 13, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 14),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(row.$1, style: TextStyle(color: c.textMuted, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(row.$2,
                          style: TextStyle(color: c.text,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'CREATED': 'Oluşturuldu', 'IN_TRANSIT': 'Taşımada',
    'IN_WAREHOUSE': 'Depoda', 'SOLD': 'Satıldı', 'RECALLED': 'Geri Çağrıldı',
  };

  static const _colors = {
    'CREATED': Color(0xFF42A5F5), 'IN_TRANSIT': Color(0xFFCE93D8),
    'IN_WAREHOUSE': Color(0xFF66BB6A), 'SOLD': Color(0xFF4DB6AC),
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
      child: Text(_labels[status] ?? status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
