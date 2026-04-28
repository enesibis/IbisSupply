import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../model/farm_record_model.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink600     = Color(0xFF52525B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);

class FarmDetailScreen extends StatelessWidget {
  final FarmRecordResponse record;
  const FarmDetailScreen({super.key, required this.record});

  static const _irrigationLabels = {
    'DRIP':      'Damla Sulama',
    'SPRINKLER': 'Yağmurlama',
    'FLOOD':     'Taşkın Sulama',
    'MANUAL':    'Manuel',
  };

  String _fmtDate(String s) {
    try {
      final p = s.split('-');
      if (p.length == 3) return '${p[2]}.${p[1]}.${p[0]}';
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
    } catch (_) { return s; }
  }

  String _fmtDateTime(String s) {
    try {
      final d = DateTime.parse(s).toLocal();
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}'
             '  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return s; }
  }

  @override
  Widget build(BuildContext context) {
    final irrigLabel = _irrigationLabels[record.irrigationType]
        ?? record.irrigationType
        ?? '—';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Tarımsal Kayıt',
            style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _line200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Hero header ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.productName,
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: _ink900,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.batchCode,
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, color: _ink400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (record.blockchainTxHash != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.link2,
                          size: 11, color: _accent),
                      const SizedBox(width: 5),
                      Text('On-chain',
                          style: AppTheme.sans(
                              fontSize: 11,
                              weight: FontWeight.w600,
                              color: _accent)),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(LucideIcons.user, size: 12, color: _ink400),
              const SizedBox(width: 5),
              Text(record.producerName,
                  style: AppTheme.sans(fontSize: 12, color: _ink500)),
              const SizedBox(width: 12),
              const Icon(LucideIcons.calendar, size: 12, color: _ink400),
              const SizedBox(width: 5),
              Text(_fmtDateTime(record.createdAt),
                  style: AppTheme.sans(fontSize: 12, color: _ink500)),
            ]),
            const SizedBox(height: 20),
            const Divider(height: 1, color: _line200),
            const SizedBox(height: 20),

            // ── Tarla Bilgileri ───────────────────────────────────────
            _Section(
              icon: LucideIcons.mapPin,
              title: 'Tarla Bilgileri',
              children: [
                _DataRow('Konum', record.fieldLocation ?? '—'),
                if (record.plantingDate != null)
                  _DataRow('Ekim Tarihi', _fmtDate(record.plantingDate!)),
                if (record.harvestDate != null)
                  _DataRow('Hasat Tarihi', _fmtDate(record.harvestDate!)),
                if (record.plantingDate == null && record.harvestDate == null)
                  _DataRow('Tarih', '—'),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sulama ────────────────────────────────────────────────
            _Section(
              icon: LucideIcons.droplets,
              title: 'Sulama',
              children: [
                _DataRow('Yöntem', irrigLabel),
                if (record.totalIrrigationHours != null)
                  _DataRow('Toplam Süre',
                      '${record.totalIrrigationHours!.toStringAsFixed(1)} saat'),
              ],
            ),
            const SizedBox(height: 12),

            // ── İlaçlar ───────────────────────────────────────────────
            if (record.pesticides != null &&
                record.pesticides!.isNotEmpty) ...[
              _Section(
                icon: LucideIcons.flaskConical,
                title: 'Kullanılan İlaçlar',
                children: [
                  _MultilineText(record.pesticides!),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Gübreler ──────────────────────────────────────────────
            if (record.fertilizers != null &&
                record.fertilizers!.isNotEmpty) ...[
              _Section(
                icon: LucideIcons.sprout,
                title: 'Kullanılan Gübreler',
                children: [
                  _MultilineText(record.fertilizers!),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Notlar ────────────────────────────────────────────────
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              _Section(
                icon: LucideIcons.fileText,
                title: 'Notlar',
                children: [
                  _MultilineText(record.notes!),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Blockchain ────────────────────────────────────────────
            _Section(
              icon: LucideIcons.link2,
              title: 'Blockchain',
              children: [
                if (record.blockchainTxHash != null) ...[
                  _DataRow('Durum', 'On-chain — doğrulandı'),
                  const SizedBox(height: 8),
                  _TxHashTile(
                    hash: record.blockchainTxHash!,
                    onCopy: () {
                      Clipboard.setData(
                          ClipboardData(text: record.blockchainTxHash!));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('TX Hash kopyalandı',
                            style: AppTheme.sans(color: Colors.white)),
                        backgroundColor: _ink900,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                      ));
                    },
                  ),
                ] else
                  _DataRow('Durum', 'Zincire yazılmadı'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _line100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: _ink500),
            ),
            const SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: AppTheme.sans(
                  fontSize: 11, weight: FontWeight.w600, color: _ink400),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _line100),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Data row ──────────────────────────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTheme.sans(fontSize: 13, color: _ink400)),
          ),
          Expanded(
            child: Text(value,
                style: AppTheme.sans(
                    fontSize: 13,
                    weight: FontWeight.w500,
                    color: _ink900)),
          ),
        ],
      ),
    );
  }
}

// ── Multiline text ────────────────────────────────────────────────────────────
class _MultilineText extends StatelessWidget {
  final String text;
  const _MultilineText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTheme.sans(fontSize: 13, color: _ink600),
        // line-by-line display
        softWrap: true);
  }
}

// ── TX hash tile ──────────────────────────────────────────────────────────────
class _TxHashTile extends StatelessWidget {
  final String hash;
  final VoidCallback onCopy;
  const _TxHashTile({required this.hash, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              hash,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: _accent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.copy, size: 14, color: _accent),
        ]),
      ),
    );
  }
}
