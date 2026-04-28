import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/quality_bloc.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink700     = Color(0xFF27272A);
const _ink600     = Color(0xFF52525B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _ink300     = Color(0xFFD4D4D8);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);
const _success    = Color(0xFF0F7A4B);
const _successSoft= Color(0xFFE6F4EE);

class QualityCreateScreen extends StatelessWidget {
  const QualityCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QualityBloc()..add(LoadBatches()),
      child: const _QualityCreateView(),
    );
  }
}

class _QualityCreateView extends StatefulWidget {
  const _QualityCreateView();
  @override
  State<_QualityCreateView> createState() => _QualityCreateViewState();
}

class _QualityCreateViewState extends State<_QualityCreateView> {
  int _step = 1;

  // Step 1
  String? _selectedBatchId;
  String? _selectedBatchLabel;
  String  _selectedResult = 'PASSED';

  // Step 2
  final _tempCtrl = TextEditingController();
  final _humCtrl  = TextEditingController();
  bool  _contamination = false;

  // Step 3
  final _notesCtrl = TextEditingController();

  static const _results = [
    {
      'value': 'PASSED',
      'label': 'Geçti',
      'desc': 'Tüm kriterler karşılandı',
      'color': Color(0xFF0F7A4B),
      'bg': Color(0xFFE6F4EE),
      'icon': LucideIcons.checkCircle2,
    },
    {
      'value': 'NEEDS_REVIEW',
      'label': 'İnceleme',
      'desc': 'Ek değerlendirme gerekli',
      'color': Color(0xFFB45309),
      'bg': Color(0xFFFBF1E1),
      'icon': LucideIcons.clock,
    },
    {
      'value': 'FAILED',
      'label': 'Başarısız',
      'desc': 'Kriterler karşılanamadı',
      'color': Color(0xFFB91C1C),
      'bg': Color(0xFFFEECEC),
      'icon': LucideIcons.xCircle,
    },
  ];

  @override
  void dispose() {
    _tempCtrl.dispose();
    _humCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_selectedBatchId == null) { _snack('Batch seçiniz'); return false; }
    return true;
  }

  void _submit(BuildContext context, List<Map<String, dynamic>> batches) {
    context.read<QualityBloc>().add(CreateCheck(
      batchId:               _selectedBatchId!,
      result:                _selectedResult,
      temperature:           _tempCtrl.text.isEmpty ? null : double.tryParse(_tempCtrl.text),
      humidity:              _humCtrl.text.isEmpty  ? null : double.tryParse(_humCtrl.text),
      contaminationDetected: _contamination,
      notes:                 _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    ));
  }

  void _snack(String msg, {Color color = _accent}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTheme.sans(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QualityBloc, QualityState>(
      listener: (context, state) {
        if (state is CheckCreated) {
          _snack('Kontrol kaydedildi', color: _success);
          context.pop();
        }
        if (state is QualityError) _snack(state.message, color: AppTheme.error);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x, size: 20, color: _ink700),
            onPressed: () => context.pop(),
          ),
          title: Text('Kalite Kontrolü',
              style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _line200),
          ),
        ),
        body: BlocBuilder<QualityBloc, QualityState>(
          builder: (context, state) {
            final batches   = state is BatchesLoaded ? state.batches : <Map<String, dynamic>>[];
            final isLoading = state is QualityLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildStepIndicator(),
                      if (_step == 1) _buildStep1(batches),
                      if (_step == 2) _buildStep2(),
                      if (_step == 3) _buildStep3(),
                    ],
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _buildFooter(context, batches, isLoading),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.shieldCheck, size: 11, color: _accent),
              const SizedBox(width: 5),
              Text('Kalite Güvencesi',
                  style: AppTheme.sans(
                      fontSize: 10, weight: FontWeight.w600, color: _accent)),
            ]),
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                  fontSize: 30, fontWeight: FontWeight.w400,
                  letterSpacing: -0.6, height: 1.15, color: _ink900),
              children: [
                const TextSpan(text: 'Kontrol '),
                TextSpan(
                  text: 'kaydı',
                  style: GoogleFonts.fraunces(
                      fontSize: 30, fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.6, color: _accent),
                ),
                const TextSpan(text: ' oluşturun.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ölçüm ve gözlemlerinizi girerek ürün\n'
            'kalitesini şeffaf biçimde belgeleyin.',
            style: AppTheme.sans(fontSize: 13, color: _ink500),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    const labels = ['Sonuç', 'Ölçümler', 'Özet'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(3, (i) {
          final n      = i + 1;
          final done   = n < _step;
          final active = n == _step;
          return Expanded(
            child: Row(children: [
              _StepCircle(n: n, done: done, active: active),
              if (active) ...[
                const SizedBox(width: 8),
                Text(labels[i],
                    style: AppTheme.sans(
                        fontSize: 12, weight: FontWeight.w600, color: _ink900)),
              ],
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: done ? _ink900 : _line200,
                  ),
                ),
            ]),
          );
        }),
      ),
    );
  }

  // ── Step 1 — Batch & Sonuç ───────────────────────────────────────────────────
  Widget _buildStep1(List<Map<String, dynamic>> batches) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Batch Seçimi'),
          _Card(child: _batchDropdown(batches)),
          const SizedBox(height: 16),
          const _Eyebrow('Kontrol Sonucu'),
          Column(
            children: _results.map((r) {
              final isSelected = _selectedResult == r['value'];
              final color = r['color'] as Color;
              final bg    = r['bg'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedResult = r['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? bg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : _line200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.12) : _line100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(r['icon'] as IconData,
                          size: 18,
                          color: isSelected ? color : _ink400),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['label'] as String,
                              style: AppTheme.sans(
                                  fontSize: 14,
                                  weight: FontWeight.w600,
                                  color: isSelected ? color : _ink900)),
                          Text(r['desc'] as String,
                              style: AppTheme.sans(
                                  fontSize: 12, color: _ink400)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.white,
                        border: Border.all(
                          color: isSelected ? color : _ink300,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(LucideIcons.check,
                              size: 11, color: Colors.white)
                          : null,
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 2 — Ölçümler & Kirlilik ────────────────────────────────────────────
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Sıcaklık & Nem'),
          _Card(
            child: Row(children: [
              Expanded(
                child: _field('Sıcaklık (°C)', _tempCtrl,
                    TextInputType.number, LucideIcons.thermometer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('Nem (%)', _humCtrl,
                    TextInputType.number, LucideIcons.droplets),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('Kirlilik Tespiti'),
          _Card(
            child: GestureDetector(
              onTap: () => setState(() => _contamination = !_contamination),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _contamination
                        ? const Color(0xFFB91C1C).withValues(alpha: 0.1)
                        : _line100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.alertTriangle,
                      size: 18,
                      color: _contamination
                          ? const Color(0xFFB91C1C)
                          : _ink400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kirlilik tespit edildi',
                          style: AppTheme.sans(
                              fontSize: 14, weight: FontWeight.w600,
                              color: _contamination
                                  ? const Color(0xFFB91C1C)
                                  : _ink900)),
                      Text(
                        _contamination
                            ? 'Ürün kirlilik içeriyor — dikkat gerekli'
                            : 'Kirlilik gözlemlenmedi',
                        style: AppTheme.sans(fontSize: 12, color: _ink400),
                      ),
                    ],
                  ),
                ),
                _IosSwitch(value: _contamination),
              ]),
            ),
          ),
          if (_contamination) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEECEC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFB91C1C).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.alertCircle,
                    size: 15, color: Color(0xFFB91C1C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kirlilik tespiti kayıt altına alındı. '
                    'Bu batch otomatik olarak incelemeye alınabilir.',
                    style: AppTheme.sans(
                        fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 3 — Notlar & Özet ───────────────────────────────────────────────────
  Widget _buildStep3() {
    final resultData = _results.firstWhere(
        (r) => r['value'] == _selectedResult);
    final color = resultData['color'] as Color;
    final bg    = resultData['bg'] as Color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          const _Eyebrow('Kontrol Özeti'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _line100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product + result badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedBatchLabel?.split(' — ').first ?? '—',
                        style: GoogleFonts.fraunces(
                            fontSize: 18, fontWeight: FontWeight.w500,
                            color: _ink900, letterSpacing: -0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: bg, borderRadius: BorderRadius.circular(999)),
                      child: Text(resultData['label'] as String,
                          style: AppTheme.sans(
                              fontSize: 11,
                              weight: FontWeight.w600,
                              color: color)),
                    ),
                  ],
                ),
                if (_selectedBatchLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _selectedBatchLabel!.contains(' — ')
                        ? _selectedBatchLabel!.split(' — ').last
                        : '',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: _ink400),
                  ),
                ],
                const SizedBox(height: 12),
                if (_tempCtrl.text.isNotEmpty) ...[
                  _summaryRow(LucideIcons.thermometer, 'Sıcaklık',
                      '${_tempCtrl.text}°C'),
                  const SizedBox(height: 6),
                ],
                if (_humCtrl.text.isNotEmpty) ...[
                  _summaryRow(LucideIcons.droplets, 'Nem',
                      '%${_humCtrl.text}'),
                  const SizedBox(height: 6),
                ],
                _summaryRow(
                  LucideIcons.alertTriangle,
                  'Kirlilik',
                  _contamination ? 'Tespit Edildi' : 'Tespit Edilmedi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Blockchain info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _successSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _success.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(LucideIcons.shieldCheck, size: 16, color: _success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu kayıt QualityRegistry akıllı sözleşmesine yazılacak '
                  've değiştirilemez hale gelecek.',
                  style: AppTheme.sans(fontSize: 12, color: _success),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Notlar
          const _Eyebrow('Notlar (opsiyonel)'),
          _Card(
            child: TextField(
              controller: _notesCtrl, maxLines: 3,
              style: AppTheme.sans(fontSize: 13, color: _ink900),
              decoration: InputDecoration(
                hintText: 'Gözlemlerinizi yazın...',
                hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _line200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _accent, width: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context,
      List<Map<String, dynamic>> batches, bool isLoading) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: _line200)),
          ),
          child: Row(children: [
            if (_step > 1) ...[
              _FooterBtn(
                label: 'Geri',
                secondary: true,
                onTap: () => setState(() => _step--),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _step < 3
                  ? _FooterBtn(
                      label: 'Devam →',
                      onTap: () {
                        if (_step == 1 && !_validateStep1()) return;
                        setState(() => _step++);
                      },
                    )
                  : _FooterBtn(
                      label: isLoading ? null : 'Kaydet',
                      loading: isLoading,
                      icon: LucideIcons.shieldCheck,
                      onTap: isLoading
                          ? null
                          : () => _submit(context, batches),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _batchDropdown(List<Map<String, dynamic>> batches) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedBatchId,
        isExpanded: true,
        dropdownColor: Colors.white,
        hint: Row(children: [
          const Icon(LucideIcons.package, size: 15, color: _ink400),
          const SizedBox(width: 8),
          Text('Batch seçin',
              style: AppTheme.sans(fontSize: 13, color: _ink400)),
        ]),
        style: AppTheme.sans(fontSize: 13, color: _ink900),
        icon: const Icon(LucideIcons.chevronDown, size: 16, color: _ink400),
        items: batches.map((b) => DropdownMenuItem<String>(
          value: b['id'].toString(),
          child: Text('${b['batchCode']} — ${b['productName']}',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sans(fontSize: 13)),
        )).toList(),
        onChanged: (v) {
          final b = batches.firstWhere((b) => b['id'].toString() == v);
          setState(() {
            _selectedBatchId    = v;
            _selectedBatchLabel = '${b['productName']} — ${b['batchCode']}';
          });
        },
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      TextInputType type, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: AppTheme.sans(fontSize: 14, color: _ink900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
        prefixIcon: Icon(icon, size: 16, color: _ink400),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _line200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: _ink400),
      const SizedBox(width: 8),
      Text('$label: ', style: AppTheme.sans(fontSize: 12, color: _ink400)),
      Expanded(
        child: Text(value,
            style: AppTheme.sans(
                fontSize: 12, weight: FontWeight.w600, color: _ink600),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StepCircle extends StatelessWidget {
  final int n;
  final bool done;
  final bool active;
  const _StepCircle({required this.n, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: done ? _ink900 : active ? _accent : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done ? _ink900 : active ? _accent : _line200,
          width: 1.5,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
            : Text('$n',
                style: AppTheme.sans(
                    fontSize: 12,
                    weight: FontWeight.w600,
                    color: active ? Colors.white : _ink400)),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: AppTheme.sans(
            fontSize: 11, weight: FontWeight.w500, color: _ink400)),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line200),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );
}

class _FooterBtn extends StatelessWidget {
  final String? label;
  final bool secondary;
  final bool loading;
  final IconData? icon;
  final VoidCallback? onTap;

  const _FooterBtn({
    this.label,
    this.secondary = false,
    this.loading = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = secondary ? Colors.white : _ink900;
    final fg = secondary ? _ink900 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 52,
        decoration: BoxDecoration(
          color: secondary ? Colors.white : bg.withValues(alpha: loading ? 0.45 : 1),
          borderRadius: BorderRadius.circular(10),
          border: secondary ? Border.all(color: _line200) : null,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 17),
                    const SizedBox(width: 8),
                  ],
                  Text(label ?? '',
                      style: AppTheme.sans(
                          fontSize: 15, weight: FontWeight.w600, color: fg)),
                ]),
        ),
      ),
    );
  }
}

class _IosSwitch extends StatelessWidget {
  final bool value;
  const _IosSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 40, height: 24,
      decoration: BoxDecoration(
        color: value ? const Color(0xFFB91C1C) : _line200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          top: 2, left: value ? 18 : 2,
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
