import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/farm_bloc.dart';
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

class FarmCreateScreen extends StatelessWidget {
  const FarmCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FarmBloc()..add(LoadBatchesForFarm()),
      child: const _FarmCreateView(),
    );
  }
}

class _FarmCreateView extends StatefulWidget {
  const _FarmCreateView();
  @override
  State<_FarmCreateView> createState() => _FarmCreateViewState();
}

class _FarmCreateViewState extends State<_FarmCreateView> {
  int _step = 1;

  // Step 1
  String?   _selectedBatchId;
  String?   _selectedBatchLabel;
  final     _fieldCtrl = TextEditingController();
  DateTime? _plantingDate;
  DateTime? _harvestDate;

  // Step 2
  String _irrigationType = 'DRIP';
  final  _irrigationHoursCtrl = TextEditingController();
  final  _pesticidesCtrl      = TextEditingController();
  final  _fertilizersCtrl     = TextEditingController();

  // Step 3
  final _notesCtrl = TextEditingController();

  static const _irrigationTypes = [
    {'value': 'DRIP',      'label': 'Damla',       'icon': LucideIcons.droplets},
    {'value': 'SPRINKLER', 'label': 'Yağmurlama',  'icon': LucideIcons.cloud},
    {'value': 'FLOOD',     'label': 'Taşkın',      'icon': LucideIcons.waves},
    {'value': 'MANUAL',    'label': 'Manuel',      'icon': LucideIcons.hand},
  ];

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _irrigationHoursCtrl.dispose();
    _pesticidesCtrl.dispose();
    _fertilizersCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_selectedBatchId == null) { _snack('Batch seçiniz'); return false; }
    return true;
  }

  void _submit(BuildContext context) {
    context.read<FarmBloc>().add(CreateFarmRecord(
      batchId:              _selectedBatchId!,
      fieldLocation:        _fieldCtrl.text.isEmpty ? null : _fieldCtrl.text,
      plantingDate:         _plantingDate?.toIso8601String().substring(0, 10),
      harvestDate:          _harvestDate?.toIso8601String().substring(0, 10),
      irrigationType:       _irrigationType,
      totalIrrigationHours: _irrigationHoursCtrl.text.isEmpty
          ? null : double.tryParse(_irrigationHoursCtrl.text),
      pesticides:  _pesticidesCtrl.text.isEmpty  ? null : _pesticidesCtrl.text,
      fertilizers: _fertilizersCtrl.text.isEmpty ? null : _fertilizersCtrl.text,
      notes:       _notesCtrl.text.isEmpty        ? null : _notesCtrl.text,
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

  void _showNoBatchesModal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _line200, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accentSoft, borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.package, color: _accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Önce bir batch oluşturun',
                style: AppTheme.sans(
                    fontSize: 17, weight: FontWeight.w700, color: _ink900)),
            const SizedBox(height: 8),
            Text(
              'Tarımsal kayıt ekleyebilmek için önce\nen az bir batch oluşturmanız gerekiyor.',
              textAlign: TextAlign.center,
              style: AppTheme.sans(fontSize: 13, color: _ink500),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  ctx.pop();
                  ctx.pop();
                  ctx.push('/batches');
                },
                child: Text('Batch Yönetimi\'ne Git',
                    style: AppTheme.sans(
                        fontSize: 14,
                        weight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  Future<void> _pickDate(bool isPlanting) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _accent, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isPlanting) { _plantingDate = picked; } else { _harvestDate = picked; }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FarmBloc, FarmState>(
      listener: (context, state) {
        if (state is FarmRecordCreated) {
          _snack('Tarımsal kayıt oluşturuldu', color: _success);
          context.pop();
        }
        if (state is FarmError) _snack(state.message, color: AppTheme.error);
        if (state is FarmBatchesLoaded) {
          final available = state.batches
              .where((b) => ['CREATED', 'IN_WAREHOUSE'].contains(b['status']))
              .toList();
          if (available.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showNoBatchesModal(context),
            );
          }
        }
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
          title: Text('Tarımsal Kayıt',
              style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _line200),
          ),
        ),
        body: BlocBuilder<FarmBloc, FarmState>(
          builder: (context, state) {
            final batches = state is FarmBatchesLoaded
                ? state.batches
                    .where((b) => ['CREATED', 'IN_WAREHOUSE'].contains(b['status']))
                    .toList()
                : <Map<String, dynamic>>[];
            final isLoading = state is FarmLoading;

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
                  child: _buildFooter(context, state, isLoading),
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
                color: _accentSoft, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.leaf, size: 11, color: _accent),
              const SizedBox(width: 5),
              Text('Tarımsal İzlenebilirlik',
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
                const TextSpan(text: 'Tarımsal '),
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
            'Ekim, sulama ve hasat verilerini girerek\n'
            'ürün geçmişini şeffaf biçimde belgeleyin.',
            style: AppTheme.sans(fontSize: 13, color: _ink500),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    const labels = ['Temel', 'Sulama', 'Özet'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(3, (i) {
          final n      = i + 1;
          final done   = n < _step;
          final active = n == _step;
          return Expanded(
            child: Row(
              children: [
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
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1 — Temel Bilgiler ──────────────────────────────────────────────────
  Widget _buildStep1(List<Map<String, dynamic>> batches) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Batch & Konum'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Batch'),
                const SizedBox(height: 6),
                _batchDropdown(batches),
                const SizedBox(height: 14),
                const _Label('Tarla / Bahçe Konumu'),
                const SizedBox(height: 6),
                _inputField(
                  'örn. Muğla / Fethiye Tarla-3',
                  _fieldCtrl,
                  icon: LucideIcons.mapPin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('Ekim & Hasat Tarihleri'),
          _Card(
            child: Row(children: [
              Expanded(child: _datePicker(true)),
              Container(width: 1, height: 60, color: _line200,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(child: _datePicker(false)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 2 — Sulama & Kimyasallar ────────────────────────────────────────────
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Sulama Yöntemi'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _irrigationSelector(),
                const SizedBox(height: 14),
                const _Label('Toplam Sulama Süresi (saat)'),
                const SizedBox(height: 6),
                _inputField(
                  'örn. 48',
                  _irrigationHoursCtrl,
                  icon: LucideIcons.timer,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('Kullanılan İlaçlar'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Her satıra bir ilaç: Ad, Doz (ml/L), Son kullanım gün',
                    style: AppTheme.sans(fontSize: 11, color: _ink400)),
                const SizedBox(height: 8),
                _textArea(
                  _pesticidesCtrl,
                  'örn. Fungisit X, 2.5 ml/L, 14 gün önce',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('Kullanılan Gübreler'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Her satıra bir gübre: Ad, Miktar (kg/dekar)',
                    style: AppTheme.sans(fontSize: 11, color: _ink400)),
                const SizedBox(height: 8),
                _textArea(
                  _fertilizersCtrl,
                  'örn. NPK 20-20-20, 5 kg/dekar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3 — Notlar & Özet ───────────────────────────────────────────────────
  Widget _buildStep3() {
    final irrigationLabel = _irrigationTypes
        .firstWhere((t) => t['value'] == _irrigationType)['label'] as String;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          const _Eyebrow('Kayıt Özeti'),
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
                // Batch
                if (_selectedBatchLabel != null) ...[
                  Text(_selectedBatchLabel!,
                      style: GoogleFonts.fraunces(
                          fontSize: 18, fontWeight: FontWeight.w500,
                          color: _ink900, letterSpacing: -0.3)),
                  const SizedBox(height: 12),
                ],
                _summaryRow(LucideIcons.mapPin, 'Konum',
                    _fieldCtrl.text.isEmpty ? '—' : _fieldCtrl.text),
                const SizedBox(height: 8),
                _summaryRow(LucideIcons.calendar, 'Ekim',
                    _plantingDate != null ? _fmtDate(_plantingDate!) : '—'),
                const SizedBox(height: 8),
                _summaryRow(LucideIcons.calendar, 'Hasat',
                    _harvestDate != null ? _fmtDate(_harvestDate!) : '—'),
                const SizedBox(height: 8),
                _summaryRow(LucideIcons.droplets, 'Sulama',
                    '$irrigationLabel'
                    '${_irrigationHoursCtrl.text.isNotEmpty ? " · ${_irrigationHoursCtrl.text} saat" : ""}'),
                if (_pesticidesCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _summaryRow(LucideIcons.flaskConical, 'İlaçlar', 'Girildi'),
                ],
                if (_fertilizersCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _summaryRow(LucideIcons.sprout, 'Gübreler', 'Girildi'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Blockchain info card
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
                  'Bu kayıt FarmRegistry akıllı sözleşmesine yazılacak '
                  've değiştirilemez hale gelecek.',
                  style: AppTheme.sans(fontSize: 12, color: _success),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Notlar
          const _Eyebrow('Ek Notlar (opsiyonel)'),
          _textArea(_notesCtrl, 'Ek gözlemler veya açıklamalar...'),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, FarmState state, bool isLoading) {
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
            if (_step > 1)
              _FooterBtn(
                label: 'Geri',
                secondary: true,
                onTap: () => setState(() => _step--),
              ),
            if (_step > 1) const SizedBox(width: 12),
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
                      accent: true,
                      icon: LucideIcons.leaf,
                      onTap: isLoading ? null : () => _submit(context),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Batch dropdown ───────────────────────────────────────────────────────────
  Widget _batchDropdown(List<Map<String, dynamic>> batches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBatchId,
          isExpanded: true,
          dropdownColor: Colors.white,
          hint: Text('Batch seçin',
              style: AppTheme.sans(fontSize: 13, color: _ink400)),
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
              _selectedBatchLabel = '${b['batchCode']} — ${b['productName']}';
            });
          },
        ),
      ),
    );
  }

  // ── Date picker ──────────────────────────────────────────────────────────────
  Widget _datePicker(bool isPlanting) {
    final date  = isPlanting ? _plantingDate : _harvestDate;
    final label = isPlanting ? 'Ekim Tarihi' : 'Hasat Tarihi';
    return GestureDetector(
      onTap: () => _pickDate(isPlanting),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.sans(fontSize: 11, color: _ink400)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(LucideIcons.calendar, size: 14, color: _ink400),
            const SizedBox(width: 6),
            Text(
              date != null ? _fmtDate(date) : 'Seç',
              style: date != null
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _ink900)
                  : AppTheme.sans(fontSize: 13, color: _ink300),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Irrigation selector ──────────────────────────────────────────────────────
  Widget _irrigationSelector() {
    return Column(
      children: [
        Row(
          children: _irrigationTypes.take(2).map((t) {
            final isSelected = _irrigationType == t['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _irrigationType = t['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent.withValues(alpha: 0.1) : _line100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _accent : _line200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Icon(t['icon'] as IconData,
                        size: 18,
                        color: isSelected ? _accent : _ink400),
                    const SizedBox(height: 4),
                    Text(t['label'] as String,
                        style: AppTheme.sans(
                            fontSize: 11,
                            weight: FontWeight.w600,
                            color: isSelected ? _accent : _ink400)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: _irrigationTypes.skip(2).map((t) {
            final isSelected = _irrigationType == t['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _irrigationType = t['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent.withValues(alpha: 0.1) : _line100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _accent : _line200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Icon(t['icon'] as IconData,
                        size: 18,
                        color: isSelected ? _accent : _ink400),
                    const SizedBox(height: 4),
                    Text(t['label'] as String,
                        style: AppTheme.sans(
                            fontSize: 11,
                            weight: FontWeight.w600,
                            color: isSelected ? _accent : _ink400)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Input field ──────────────────────────────────────────────────────────────
  Widget _inputField(String hint, TextEditingController ctrl,
      {IconData? icon, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: AppTheme.sans(fontSize: 14, color: _ink900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
        prefixIcon: icon != null ? Icon(icon, size: 16, color: _ink400) : null,
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

  // ── Text area ────────────────────────────────────────────────────────────────
  Widget _textArea(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl, maxLines: 3,
      style: AppTheme.sans(fontSize: 13, color: _ink900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sans(fontSize: 12, color: _ink400),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
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

  // ── Summary row ──────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: AppTheme.sans(
              fontSize: 11, weight: FontWeight.w500, color: _ink400)),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTheme.sans(fontSize: 12, weight: FontWeight.w500, color: _ink600));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final String? label;
  final bool secondary;
  final bool accent;
  final bool loading;
  final IconData? icon;
  final VoidCallback? onTap;

  const _FooterBtn({
    this.label,
    this.secondary = false,
    this.accent = false,
    this.loading = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = secondary
        ? Colors.white
        : accent
            ? _accent
            : _ink900;
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fg))
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
