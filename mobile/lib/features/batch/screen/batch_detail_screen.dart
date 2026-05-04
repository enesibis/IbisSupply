import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
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

  int _daysRemaining(String expiryDate) {
    try {
      return DateTime.parse(expiryDate).difference(DateTime.now()).inDays;
    } catch (_) { return 0; }
  }

  void _copyToClipboard(BuildContext ctx, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('$label kopyalandı', style: AppTheme.sans()),
      backgroundColor: AppTheme.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showQrDialog(BuildContext ctx, String batchCode) {
    showDialog(
      context: ctx,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Kod',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A0A0B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                batchCode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: batchCode,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _copyToClipboard(ctx, batchCode, 'Batch kodu');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE4E4E7)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Kopyala', style: AppTheme.sans()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A0A0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Kapat', style: AppTheme.sans()),
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

  String _statusShort(String status) {
    switch (status) {
      case 'CREATED':     return 'Aktif';
      case 'IN_TRANSIT':  return 'Yolda';
      case 'IN_WAREHOUSE': return 'Depoda';
      case 'SOLD':        return 'Teslim';
      case 'RECALLED':    return 'İade';
      default:            return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SOLD':     return AppTheme.riskLow;
      case 'RECALLED': return AppTheme.error;
      case 'IN_TRANSIT': return AppTheme.accent;
      default: return AppTheme.ink;
    }
  }

  List<Widget> _buildTimeline(BatchResponse batch, bool hasCert) {
    final events = <({IconData icon, String title, String sub, String date, String? tx})>[];

    events.add((
      icon: LucideIcons.package,
      title: 'Batch oluşturuldu',
      sub: '${batch.quantity.toStringAsFixed(0)} ${batch.unit} · ${batch.organizationName}',
      date: _formatDateTime(batch.createdAt),
      tx: batch.blockchainTxHash != null
          ? '${batch.blockchainTxHash!.substring(0, 10)}…'
          : null,
    ));

    if (hasCert) {
      final tokenId = _cert!['tokenId'] ?? '—';
      events.add((
        icon: LucideIcons.shieldCheck,
        title: 'Kalite onaylandı · NFT mint',
        sub: 'Token #$tokenId · ERC-721',
        date: _formatDateTime(batch.createdAt),
        tx: null,
      ));
    }

    return List.generate(events.length, (i) {
      final e = events[i];
      final isFirst = i == 0;
      final isLast = i == events.length - 1;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isFirst ? AppTheme.accent : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(e.icon, size: 15,
                      color: isFirst ? Colors.white : const Color(0xFF52525B)),
                ),
                if (!isLast)
                  Container(
                    width: 1, height: 20,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE4E4E7),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: AppTheme.sans(fontSize: 13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(e.sub,
                      style: AppTheme.sans(
                          fontSize: 12, color: const Color(0xFF71717A))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(e.date,
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10, color: const Color(0xFFA1A1AA))),
                      if (e.tx != null) ...[
                        const Spacer(),
                        Text(e.tx!,
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10, color: AppTheme.accent)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final daysLeft = _daysRemaining(batch.expiryDate);
    final hasCert = !_certLoading && _cert != null && _cert!['exists'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          color: AppTheme.ink,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Batch detayı',
            style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 18),
            color: AppTheme.ink,
            onPressed: () => _copyToClipboard(context, batch.batchCode, 'Batch kodu'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, size: 18),
            color: AppTheme.ink,
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4E4E7)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (batch.blockchainTxHash != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.link2,
                              size: 12, color: Color(0xFF3F3FE8)),
                          const SizedBox(width: 5),
                          Text("Blockchain'de",
                              style: AppTheme.sans(
                                  fontSize: 11,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF3F3FE8))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    batch.productName,
                    style: GoogleFonts.fraunces(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.72,
                      height: 1.1,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${batch.organizationName} · ${_formatDate(batch.productionDate)}',
                    style: AppTheme.sans(
                        fontSize: 14, color: const Color(0xFF71717A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    batch.batchCode,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, color: const Color(0xFFA1A1AA)),
                  ),
                ],
              ),
            ),

            // ── Metrics ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Miktar',
                      value: batch.quantity.toStringAsFixed(0),
                      unit: batch.unit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'Kalan raf',
                      value: daysLeft > 0 ? '$daysLeft' : '0',
                      unit: 'gün',
                      valueColor: daysLeft <= 0
                          ? AppTheme.error
                          : daysLeft <= 3
                              ? AppTheme.riskMedium
                              : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'Durum',
                      value: _statusShort(batch.status),
                      unit: '',
                      valueColor: _statusColor(batch.status),
                    ),
                  ),
                ],
              ),
            ),

            // ── QR ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      child: QrImageView(
                        data: batch.qrCode,
                        size: 72,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tüketici QR kodu',
                              style: AppTheme.sans(
                                  fontSize: 14, weight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Bu kodu paylaşarak tüm tedarik zinciri geçmişini gösterebilirsiniz.',
                            style: AppTheme.sans(
                                fontSize: 12,
                                color: const Color(0xFF71717A)),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _copyToClipboard(
                                context, batch.batchCode, 'Batch kodu'),
                            child: Text('İndir →',
                                style: AppTheme.sans(
                                    fontSize: 12,
                                    weight: FontWeight.w600,
                                    color: AppTheme.accent)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Timeline ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Eyebrow('Zincir geçmişi'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Column(children: _buildTimeline(batch, hasCert)),
                  ),
                ],
              ),
            ),

            // ── NFT certificate ───────────────────────────────────────
            if (_certLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(width: 12),
                      Text('Sertifika kontrol ediliyor...',
                          style: AppTheme.sans(
                              fontSize: 13, color: const Color(0xFF71717A))),
                    ],
                  ),
                ),
              )
            else if (hasCert)
              _NftCard(
                cert: _cert!,
                productName: batch.productName,
                batchCode: batch.batchCode,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.award,
                            size: 18, color: Color(0xFFD4D4D8)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NFT sertifikası yok',
                              style: AppTheme.sans(
                                  fontSize: 13, weight: FontWeight.w500)),
                          Text('Kalite kontrolü geçildiğinde mint edilir',
                              style: AppTheme.sans(
                                  fontSize: 11,
                                  color: const Color(0xFFA1A1AA))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ── Blockchain TX ─────────────────────────────────────────
            if (batch.blockchainTxHash != null)
              _BlockchainCard(
                txHash: batch.blockchainTxHash!,
                onCopy: () =>
                    _copyToClipboard(context, batch.blockchainTxHash!, 'TX Hash'),
              ),

            // ── Info sections ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _InfoSection(
                title: 'Ürün bilgileri',
                icon: LucideIcons.package,
                rows: [
                  ('Ürün adı', batch.productName),
                  ('Kategori', batch.productCategory),
                  ('Miktar', '${batch.quantity.toStringAsFixed(0)} ${batch.unit}'),
                  ('Menşei', batch.originLocation ?? '—'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _InfoSection(
                title: 'Tarih bilgileri',
                icon: LucideIcons.calendar,
                rows: [
                  ('Üretim tarihi', _formatDate(batch.productionDate)),
                  ('Son kullanma', _formatDate(batch.expiryDate)),
                  ('Oluşturulma', _formatDateTime(batch.createdAt)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _InfoSection(
                title: 'Üretici bilgileri',
                icon: LucideIcons.building2,
                rows: [
                  ('Üretici', batch.producerName),
                  ('Organizasyon', batch.organizationName),
                ],
              ),
            ),

            // ── CTA ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.truck,
                            size: 16, color: Colors.white),
                        label: Text('Sevkiyat başlat',
                            style: AppTheme.sans(
                                fontSize: 14,
                                weight: FontWeight.w600,
                                color: Colors.white)),
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.ink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.qrCode, size: 18),
                      color: AppTheme.ink,
                      onPressed: () => _showQrDialog(context, batch.batchCode),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.sans(
                fontSize: 10,
                color: const Color(0xFFA1A1AA),
                weight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: valueColor ?? AppTheme.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(unit,
                    style: AppTheme.sans(
                        fontSize: 12, color: const Color(0xFF71717A))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Eyebrow ───────────────────────────────────────────────────────────────────
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFA1A1AA),
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── NFT certificate card ──────────────────────────────────────────────────────
class _NftCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  final String productName;
  final String batchCode;
  const _NftCard(
      {required this.cert,
      required this.productName,
      required this.batchCode});

  @override
  Widget build(BuildContext context) {
    final tokenId = cert['tokenId'] ?? '—';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
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
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2),
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
                    border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.35)),
                  ),
                  child: const Icon(LucideIcons.award,
                      color: Color(0xFFFFD54F), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NFT Kalite Sertifikası',
                          style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('ERC-721 · IbisSupply Certificate',
                          style: TextStyle(
                              color: Color(0xFFFFD54F), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7A4B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF0F7A4B).withValues(alpha: 0.4)),
                  ),
                  child: const Text('ONAYLANMIŞ',
                      style: TextStyle(
                          color: Color(0xFF0F7A4B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _CertItem(label: 'Token ID', value: '#$tokenId')),
                Expanded(
                    child: _CertItem(label: 'Tür', value: 'QUALITY_PASS')),
              ],
            ),
            const SizedBox(height: 8),
            _CertItem(label: 'Ürün', value: productName),
            const SizedBox(height: 8),
            _CertItem(label: 'Batch', value: batchCode, mono: true),
          ],
        ),
      ),
    );
  }
}

class _CertItem extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _CertItem(
      {required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'JetBrainsMono' : null),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Blockchain TX card ────────────────────────────────────────────────────────
class _BlockchainCard extends StatelessWidget {
  final String txHash;
  final VoidCallback onCopy;
  const _BlockchainCard({required this.txHash, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2E1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF0F7A4B).withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0F7A4B).withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2),
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
                    color: const Color(0xFF0F7A4B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF0F7A4B).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(LucideIcons.link2,
                      color: Color(0xFF0F7A4B), size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Blockchain'e Yazıldı",
                          style: TextStyle(
                              color: Color(0xFF0F7A4B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('Ethereum Hardhat Testnet · Chain 31337',
                          style: TextStyle(
                              color: Color(0xFF0F7A4B), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF0F7A4B), shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('TX Hash',
                style: TextStyle(
                    color: const Color(0xFF0F7A4B).withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(txHash,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono',
                          letterSpacing: 0.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7A4B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF0F7A4B).withValues(alpha: 0.25)),
                    ),
                    child: const Icon(LucideIcons.copy,
                        color: Color(0xFF0F7A4B), size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info section ──────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> rows;
  const _InfoSection(
      {required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFFA1A1AA)),
              const SizedBox(width: 7),
              Text(title,
                  style: AppTheme.sans(
                      fontSize: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF52525B))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(row.$1,
                          style: AppTheme.sans(
                              fontSize: 13, color: const Color(0xFFA1A1AA))),
                    ),
                    Expanded(
                      child: Text(row.$2,
                          style: AppTheme.sans(
                              fontSize: 13, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
