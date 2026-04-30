import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/shipment_bloc.dart';
import '../../batch/bloc/batch_bloc.dart';
import '../../batch/model/batch_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink700     = Color(0xFF27272A);
const _ink600     = Color(0xFF52525B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);
const _success    = Color(0xFF0F7A4B);
const _successSoft= Color(0xFFE6F4EE);

class ShipmentCreateScreen extends StatelessWidget {
  const ShipmentCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ShipmentBloc()),
        BlocProvider(create: (_) => BatchBloc()..add(LoadBatches())),
      ],
      child: const _ShipmentCreateView(),
    );
  }
}

class _ShipmentCreateView extends StatefulWidget {
  const _ShipmentCreateView();
  @override
  State<_ShipmentCreateView> createState() => _ShipmentCreateViewState();
}

class _ShipmentCreateViewState extends State<_ShipmentCreateView> {
  int _step = 1;

  // Step 1
  BatchResponse?      _selectedBatch;
  final _fromCtrl   = TextEditingController();
  final _toCtrl     = TextEditingController();

  // Step 2
  final _plateCtrl  = TextEditingController();
  String? _vehicleType;
  String? _weatherCondition;
  String? _trafficLevel;

  // Step 3
  final _distanceCtrl     = TextEditingController();
  final _plannedHoursCtrl = TextEditingController();
  final _notesCtrl        = TextEditingController();

  List<BatchResponse> _batches = [];

  String _currentRole = '';
  bool _batchHasFarmRecord = true;
  bool _checkingFarmRecord = false;

  static const _vehicleTypes = [
    {'value': 'TRUCK',             'label': 'Kamyon',     'icon': LucideIcons.truck},
    {'value': 'REFRIGERATED_TRUCK','label': 'Frigorifik', 'icon': LucideIcons.thermometer},
    {'value': 'VAN',               'label': 'Minivan',    'icon': LucideIcons.car},
  ];

  static const _weatherOptions = [
    {'value': 'CLEAR',  'label': 'Açık',     'icon': LucideIcons.sun},
    {'value': 'CLOUDY', 'label': 'Bulutlu',  'icon': LucideIcons.cloud},
    {'value': 'RAIN',   'label': 'Yağmurlu', 'icon': LucideIcons.cloudRain},
    {'value': 'FOG',    'label': 'Sisli',    'icon': LucideIcons.wind},
    {'value': 'SNOW',   'label': 'Karlı',    'icon': LucideIcons.snowflake},
  ];

  static const _trafficOptions = [
    {'value': 'LOW',    'label': 'Az'},
    {'value': 'MEDIUM', 'label': 'Orta'},
    {'value': 'HIGH',   'label': 'Yoğun'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthStorage.getRole();
    if (mounted) setState(() => _currentRole = role ?? '');
  }

  Future<void> _checkFarmRecord(String batchId) async {
    setState(() => _checkingFarmRecord = true);
    try {
      final Dio dio = ApiClient.create();
      final res = await dio.get('/farm-records');
      final records = (res.data as List).cast<Map<String, dynamic>>();
      final has = records.any((r) => r['batchId'] == batchId);
      if (mounted) setState(() { _batchHasFarmRecord = has; _checkingFarmRecord = false; });
    } catch (_) {
      if (mounted) setState(() { _batchHasFarmRecord = true; _checkingFarmRecord = false; });
    }
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
              decoration: BoxDecoration(color: _line200, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.package, color: _accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Önce bir batch oluşturun',
                style: AppTheme.sans(fontSize: 17, weight: FontWeight.w700, color: _ink900)),
            const SizedBox(height: 8),
            Text(
              'Sevkiyat oluşturmak için önce\nen az bir batch olması gerekiyor.',
              textAlign: TextAlign.center,
              style: AppTheme.sans(fontSize: 13, color: _ink500),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  ctx.pop();
                  ctx.pop();
                  ctx.push('/batches');
                },
                child: Text('Batch Yönetimi\'ne Git',
                    style: AppTheme.sans(
                        fontSize: 14, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromCtrl.dispose(); _toCtrl.dispose(); _plateCtrl.dispose();
    _distanceCtrl.dispose(); _plannedHoursCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_selectedBatch == null) { _snack('Batch seçiniz'); return false; }
    if (_fromCtrl.text.trim().isEmpty) { _snack('Çıkış noktası gerekli'); return false; }
    if (_toCtrl.text.trim().isEmpty)   { _snack('Varış noktası gerekli'); return false; }
    if (_currentRole == 'PRODUCER' && !_batchHasFarmRecord) {
      _snack('Seçilen batch için tarımsal kayıt eklenmemiş');
      return false;
    }
    return true;
  }

  void _submit() {
    context.read<ShipmentBloc>().add(CreateShipment(
      batchId:          _selectedBatch!.id,
      fromLocation:     _fromCtrl.text.trim(),
      toLocation:       _toCtrl.text.trim(),
      vehiclePlate:     _plateCtrl.text.trim().isEmpty ? null : _plateCtrl.text.trim(),
      notes:            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      distanceKm:       double.tryParse(_distanceCtrl.text.replaceAll(',', '.')),
      plannedHours:     double.tryParse(_plannedHoursCtrl.text.replaceAll(',', '.')),
      vehicleType:      _vehicleType,
      weatherCondition: _weatherCondition,
      trafficLevel:     _trafficLevel,
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
    return MultiBlocListener(
      listeners: [
        BlocListener<BatchBloc, BatchState>(
          listener: (context, state) {
            if (state is BatchListLoaded) {
              final available = state.batches
                  .where((b) => ['CREATED', 'IN_WAREHOUSE'].contains(b.status))
                  .toList();
              setState(() => _batches = available);
              if (available.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _showNoBatchesModal(context),
                );
              }
            }
          },
        ),
        BlocListener<ShipmentBloc, ShipmentState>(
          listener: (context, state) {
            if (state is ShipmentCreated) {
              _snack('Sevkiyat oluşturuldu: ${state.shipment.shipmentCode}',
                  color: _success);
              Navigator.pop(context, true);
            }
            if (state is ShipmentError) _snack(state.message, color: AppTheme.error);
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x, size: 20, color: _ink700),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Yeni Sevkiyat',
              style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _line200),
          ),
        ),
        body: BlocBuilder<ShipmentBloc, ShipmentState>(
          builder: (context, state) {
            final isLoading = state is ShipmentLoading;
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildStepIndicator(),
                      if (_step == 1) _buildStep1(),
                      if (_step == 2) _buildStep2(),
                      if (_step == 3) _buildStep3(),
                    ],
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _buildFooter(context, isLoading),
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
              const Icon(LucideIcons.link2, size: 11, color: _accent),
              const SizedBox(width: 5),
              Text('Blockchain\'e yazılacak',
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
                const TextSpan(text: 'Sevkiyatı '),
                TextSpan(
                  text: 'başlatın',
                  style: GoogleFonts.fraunces(
                      fontSize: 30, fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.6, color: _accent),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Güzergah, araç ve koşulları girerek\n'
            'lojistik kaydını şeffaf biçimde belgeleyin.',
            style: AppTheme.sans(fontSize: 13, color: _ink500),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    const labels = ['Güzergah', 'Araç', 'Detaylar'];
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

  // ── Step 1 — Batch & Güzergah ────────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Batch Seçimi'),
          _Card(
            child: BlocBuilder<BatchBloc, BatchState>(
              builder: (context, batchState) {
                if (batchState is BatchLoading && _batches.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: _accent, strokeWidth: 2),
                    ),
                  );
                }
                return _batchDropdown();
              },
            ),
          ),
          if (_currentRole == 'PRODUCER' && _selectedBatch != null && !_checkingFarmRecord && !_batchHasFarmRecord)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(children: [
                  const Icon(LucideIcons.alertTriangle, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu batch için tarımsal kayıt yok — önce ekleyin.',
                      style: AppTheme.sans(
                          fontSize: 12, weight: FontWeight.w500,
                          color: const Color(0xFFB45309)),
                    ),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 16),
          const _Eyebrow('Güzergah'),
          _Card(
            child: Column(children: [
              _field(_fromCtrl, 'Çıkış noktası', LucideIcons.mapPin),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _line100,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _line200),
                      ),
                      child: const Icon(LucideIcons.arrowDown,
                          color: _ink400, size: 14),
                    ),
                  ],
                ),
              ),
              _field(_toCtrl, 'Varış noktası', LucideIcons.flag),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 2 — Araç & Koşullar ─────────────────────────────────────────────────
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Araç Tipi'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: _vehicleTypes.map((t) {
                    final selected = _vehicleType == t['value'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _vehicleType = t['value'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? _accent.withValues(alpha: 0.1)
                                : _line100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? _accent : _line200,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(t['icon'] as IconData,
                                size: 18,
                                color: selected ? _accent : _ink400),
                            const SizedBox(height: 4),
                            Text(t['label'] as String,
                                style: AppTheme.sans(
                                    fontSize: 10,
                                    weight: FontWeight.w600,
                                    color: selected ? _accent : _ink400)),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const _Label('Plaka (opsiyonel)'),
                const SizedBox(height: 6),
                _field(_plateCtrl, 'örn. 34 ABC 123', LucideIcons.car),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('Hava Durumu (opsiyonel)'),
          _Card(
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _weatherOptions.map((w) {
                final selected = _weatherCondition == w['value'];
                return GestureDetector(
                  onTap: () => setState(() =>
                      _weatherCondition = selected ? null : w['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _accent.withValues(alpha: 0.1) : _line100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _accent : _line200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(w['icon'] as IconData,
                          size: 13,
                          color: selected ? _accent : _ink400),
                      const SizedBox(width: 6),
                      Text(w['label'] as String,
                          style: AppTheme.sans(
                              fontSize: 12,
                              weight: FontWeight.w600,
                              color: selected ? _accent : _ink400)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('Trafik Yoğunluğu (opsiyonel)'),
          _Card(
            child: Row(
              children: _trafficOptions.map((t) {
                final selected = _trafficLevel == t['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() =>
                        _trafficLevel = selected ? null : t['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _accent.withValues(alpha: 0.1) : _line100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _accent : _line200,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(t['label'] as String,
                          textAlign: TextAlign.center,
                          style: AppTheme.sans(
                              fontSize: 12,
                              weight: FontWeight.w600,
                              color: selected ? _accent : _ink400)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3 — Detaylar & Özet ─────────────────────────────────────────────────
  Widget _buildStep3() {
    final vehicleLabel = _vehicleType == null
        ? '—'
        : (_vehicleTypes.firstWhere(
                (t) => t['value'] == _vehicleType)['label'] as String);
    final weatherLabel = _weatherCondition == null
        ? '—'
        : (_weatherOptions.firstWhere(
                (w) => w['value'] == _weatherCondition)['label'] as String);
    final trafficLabel = _trafficLevel == null
        ? '—'
        : (_trafficOptions.firstWhere(
                (t) => t['value'] == _trafficLevel)['label'] as String);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mesafe & Süre
          const _Eyebrow('Rota Detayları (opsiyonel)'),
          _Card(
            child: Row(children: [
              Expanded(
                child: _field(_distanceCtrl, 'Mesafe (km)',
                    LucideIcons.ruler,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(_plannedHoursCtrl, 'Süre (saat)',
                    LucideIcons.timer,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Notlar
          const _Eyebrow('Notlar (opsiyonel)'),
          _Card(
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3, minLines: 2,
              style: AppTheme.sans(fontSize: 14, color: _ink900),
              decoration: InputDecoration(
                hintText: 'Taşıma koşulları, özel talimatlar...',
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
          const SizedBox(height: 16),

          // Summary card
          const _Eyebrow('Sevkiyat Özeti'),
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
                if (_selectedBatch != null) ...[
                  Text(
                    _selectedBatch!.productName,
                    style: GoogleFonts.fraunces(
                        fontSize: 17, fontWeight: FontWeight.w500,
                        color: _ink900, letterSpacing: -0.3),
                  ),
                  Text(_selectedBatch!.batchCode,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: _ink400)),
                  const SizedBox(height: 12),
                ],
                _summaryRow(LucideIcons.mapPin, 'Çıkış',   _fromCtrl.text),
                const SizedBox(height: 6),
                _summaryRow(LucideIcons.flag,   'Varış',   _toCtrl.text),
                const SizedBox(height: 6),
                _summaryRow(LucideIcons.truck,  'Araç',    vehicleLabel),
                const SizedBox(height: 6),
                _summaryRow(LucideIcons.cloud,  'Hava',    weatherLabel),
                const SizedBox(height: 6),
                _summaryRow(LucideIcons.ganttChart, 'Trafik', trafficLabel),
                if (_distanceCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _summaryRow(LucideIcons.ruler, 'Mesafe',
                      '${_distanceCtrl.text} km'),
                ],
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
                  'Bu sevkiyat ShipmentRegistry akıllı sözleşmesine yazılacak '
                  've değiştirilemez hale gelecek.',
                  style: AppTheme.sans(fontSize: 12, color: _success),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, bool isLoading) {
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
                      label: isLoading ? null : 'Sevkiyat Oluştur',
                      loading: isLoading,
                      icon: LucideIcons.truck,
                      onTap: isLoading ? null : _submit,
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _batchDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<BatchResponse>(
        value: _selectedBatch,
        isExpanded: true,
        dropdownColor: Colors.white,
        hint: Row(children: [
          const Icon(LucideIcons.package, size: 15, color: _ink400),
          const SizedBox(width: 8),
          Text('Batch seçin', style: AppTheme.sans(fontSize: 13, color: _ink400)),
        ]),
        style: AppTheme.sans(fontSize: 13, color: _ink900),
        icon: const Icon(LucideIcons.chevronDown, size: 16, color: _ink400),
        items: _batches.map((b) => DropdownMenuItem(
          value: b,
          child: Text('${b.productName} — ${b.batchCode}',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sans(fontSize: 13)),
        )).toList(),
        onChanged: (v) {
          setState(() {
            _selectedBatch = v;
            _batchHasFarmRecord = true;
          });
          if (v != null && _currentRole == 'PRODUCER') {
            _checkFarmRecord(v.id);
          }
        },
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
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
        style: AppTheme.sans(fontSize: 11, weight: FontWeight.w500, color: _ink400)),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTheme.sans(fontSize: 12, weight: FontWeight.w500, color: _ink600));
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
