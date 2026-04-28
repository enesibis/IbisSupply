import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../bloc/batch_bloc.dart';
import '../model/batch_model.dart';
import '../../../core/api/api_client.dart';
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

class BatchCreateScreen extends StatelessWidget {
  const BatchCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BatchBloc()..add(LoadProducts()),
      child: const _BatchCreateView(),
    );
  }
}

class _BatchCreateView extends StatefulWidget {
  const _BatchCreateView();
  @override
  State<_BatchCreateView> createState() => _BatchCreateViewState();
}

class _BatchCreateViewState extends State<_BatchCreateView> {
  int _step = 1;

  // Step 1
  ProductItem? _selectedProduct;
  final _quantityCtrl = TextEditingController();
  String _unit = 'KG';
  bool _isOrganic   = false;
  bool _isColdChain = false;
  List<ProductItem> _products = [];

  // Step 2
  final _locationCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  DateTime _harvestDate  = DateTime.now();
  int      _shelfLifeDays = 14;
  bool     _loadingShelfLife = false;

  final Dio _dio = ApiClient.create();

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchShelfLife(String category) async {
    setState(() => _loadingShelfLife = true);
    try {
      final res = await _dio.get('/products/shelf-life/$category');
      final days = res.data['optimal_days'] as int? ?? 14;
      setState(() { _shelfLifeDays = days; _loadingShelfLife = false; });
    } catch (_) {
      setState(() => _loadingShelfLife = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _harvestDate = picked);
  }

  void _submit() {
    final expiry = _harvestDate.add(Duration(days: _shelfLifeDays));
    String? notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;
    final certs = [
      if (_isOrganic)   'Organik Üretim',
      if (_isColdChain) 'Soğuk Zincir',
    ];
    if (certs.isNotEmpty) {
      final tag = 'Sertifikalar: ${certs.join(', ')}';
      notes = notes != null ? '$notes · $tag' : tag;
    }
    context.read<BatchBloc>().add(CreateBatch(
      productId: _selectedProduct!.id,
      quantity: double.parse(_quantityCtrl.text.replaceAll(',', '.')),
      unit: _unit,
      productionDate: _harvestDate.toIso8601String().split('T').first,
      expiryDate: expiry.toIso8601String().split('T').first,
      originLocation: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  bool _validateStep1() {
    if (_selectedProduct == null) { _snack('Ürün seçiniz'); return false; }
    final q = _quantityCtrl.text.replaceAll(',', '.');
    if (q.isEmpty || double.tryParse(q) == null) {
      _snack('Geçerli bir miktar girin'); return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BatchBloc, BatchState>(
      listener: (context, state) {
        if (state is ProductsLoaded) setState(() => _products = state.products);
        if (state is BatchCreated) {
          _snack('Batch oluşturuldu: ${state.batch.batchCode}', color: _success);
          Navigator.pop(context, true);
        }
        if (state is BatchError) _snack(state.message, color: AppTheme.error);
      },
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
          title: Text('Yeni Batch',
              style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _line200),
          ),
        ),
        body: BlocBuilder<BatchBloc, BatchState>(
          builder: (context, state) {
            if (state is BatchLoading && _products.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent));
            }
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
                      if (_step == 3) _buildStep3(state),
                    ],
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _buildFooter(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag
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
          // Display heading
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 32, fontWeight: FontWeight.w400,
                letterSpacing: -0.64, height: 1.1, color: _ink900),
              children: [
                const TextSpan(text: 'Yeni bir '),
                TextSpan(
                  text: 'batch',
                  style: GoogleFonts.fraunces(
                    fontSize: 32, fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.64, color: _accent),
                ),
                const TextSpan(text: ' oluşturun.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kayıt onaylandıktan sonra ürünün tedarik zinciri başlar\n'
            've değiştirilemez bir geçmişe eklenir.',
            style: AppTheme.sans(fontSize: 13, color: _ink500),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    const labels = ['Ürün', 'Köken', 'Onay'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(3, (i) {
          final n = i + 1;
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

  // ── Step 1 — Ürün ───────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('Ürün bilgileri'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Ürün'),
                const SizedBox(height: 6),
                _ProductPicker(
                  products: _products,
                  selected: _selectedProduct,
                  onSelect: (p) {
                    setState(() { _selectedProduct = p; _unit = p.unit; });
                    _fetchShelfLife(p.category);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Miktar'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _quantityCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: AppTheme.sans(fontSize: 15),
                            decoration: _inputDeco('0', prefix: LucideIcons.hash),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Birim'),
                          const SizedBox(height: 6),
                          _UnitSegment(
                            selected: _unit,
                            onSelect: (u) => setState(() => _unit = u),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Eyebrow('Sertifika'),
          _Card(
            padding: 0,
            child: Column(children: [
              _ToggleRow(
                icon: LucideIcons.leaf,
                label: 'Organik üretim',
                sub: 'TR Organik · sertifikalı',
                value: _isOrganic,
                onToggle: () => setState(() => _isOrganic = !_isOrganic),
                isLast: false,
              ),
              _ToggleRow(
                icon: LucideIcons.snowflake,
                label: 'Soğuk zincir',
                sub: '2 °C — 8 °C arası taşıma',
                value: _isColdChain,
                onToggle: () => setState(() => _isColdChain = !_isColdChain),
                isLast: true,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 2 — Köken ──────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('Köken'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Üretim yeri'),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationCtrl,
                  style: AppTheme.sans(fontSize: 15),
                  decoration: _inputDeco('Çiftlik adı · konum',
                      prefix: LucideIcons.mapPin),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Eyebrow('Hasat ve ömür'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Hasat tarihi'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _line200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(LucideIcons.calendar, size: 16, color: _ink400),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_fmt(_harvestDate),
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _ink900)),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: _ink300),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                _Label('Tahmini raf ömrü'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _line200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        if (_shelfLifeDays > 1) {
                          setState(() => _shelfLifeDays--);
                        }
                      },
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: _line200),
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white,
                        ),
                        child: const Icon(LucideIcons.minus,
                            size: 14, color: _ink700),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('$_shelfLifeDays',
                                style: GoogleFonts.fraunces(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.5,
                                    color: _ink900)),
                            const SizedBox(width: 6),
                            Text('gün',
                                style: AppTheme.sans(
                                    fontSize: 13, color: _ink500)),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _shelfLifeDays++),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: _line200),
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white,
                        ),
                        child: const Icon(LucideIcons.plus,
                            size: 14, color: _ink700),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                if (_loadingShelfLife)
                  Row(children: [
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: _accent),
                    ),
                    const SizedBox(width: 8),
                    Text('AI tahmini yükleniyor...',
                        style: AppTheme.sans(fontSize: 11, color: _ink400)),
                  ])
                else
                  Text(
                    'AI tahmini · hasat tarihinden itibaren $_shelfLifeDays gün',
                    style: AppTheme.sans(fontSize: 11, color: _ink400),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Eyebrow('Notlar'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _line200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 4, minLines: 3,
              style: AppTheme.sans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Bu batch\'e dair açıklamalar (opsiyonel)…',
                hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3 — Onay ──────────────────────────────────────────────────────────
  Widget _buildStep3(BatchState state) {
    final expiry = _harvestDate.add(Duration(days: _shelfLifeDays));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('Özet'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedProduct?.name ?? '',
                  style: GoogleFonts.fraunces(
                      fontSize: 28, fontWeight: FontWeight.w400,
                      letterSpacing: -0.5, color: _ink900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    _PillTag(_selectedProduct?.category ?? ''),
                    if (_isOrganic)
                      _PillTag('Organik',
                          variant: 'success', icon: LucideIcons.leaf),
                    if (_isColdChain)
                      _PillTag('Soğuk zincir',
                          variant: 'accent', icon: LucideIcons.snowflake),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: _line100),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _SummaryField(
                      'Miktar', '${_quantityCtrl.text} $_unit')),
                  Expanded(child: _SummaryField(
                      'Raf ömrü', '$_shelfLifeDays gün')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryField('Hasat', _fmt(_harvestDate))),
                  Expanded(child: _SummaryField('Son kullanma', _fmt(expiry))),
                ]),
                if (_locationCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SummaryField('Köken', _locationCtrl.text),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: _line100),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Önizleme kodu',
                        style: AppTheme.sans(
                            fontSize: 10,
                            weight: FontWeight.w500,
                            color: _ink400)),
                    Text('BTCH-XXXXXX',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, color: _ink700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Eyebrow('Blockchain işlemi'),
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.link2,
                      size: 17, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BatchRegistry sözleşmesi',
                          style: AppTheme.sans(
                              fontSize: 13,
                              weight: FontWeight.w600,
                              color: _ink900)),
                      const SizedBox(height: 4),
                      Text(
                        'Bu kayıt onaylandıktan sonra değiştirilemez. '
                        'Lokal Hardhat ağına yazılacak.',
                        style: AppTheme.sans(fontSize: 12, color: _ink500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky footer ────────────────────────────────────────────────────────────
  Widget _buildFooter(BatchState state) {
    final loading = state is BatchLoading;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: _line100)),
          ),
          child: Row(children: [
            if (_step > 1)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FooterBtn(
                  onTap: () => setState(() => _step--),
                  variant: 'secondary',
                  icon: LucideIcons.arrowLeft,
                  label: 'Geri',
                ),
              ),
            Expanded(
              child: _step < 3
                  ? _FooterBtn(
                      onTap: () {
                        if (_step == 1 && !_validateStep1()) return;
                        setState(() => _step++);
                      },
                      variant: 'primary',
                      label: 'Devam et →',
                    )
                  : _FooterBtn(
                      onTap: loading ? null : _submit,
                      variant: 'accent',
                      icon: loading ? null : LucideIcons.check,
                      label: loading ? '' : 'Blockchain\'e kaydet',
                      loading: loading,
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, {IconData? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.sans(fontSize: 13, color: _ink400),
      prefixIcon: prefix != null
          ? Icon(prefix, size: 16, color: _ink400)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent, width: 1.5)),
    );
  }
}

// ─────────────────────────────────────────────────── Küçük bileşenler ─────────

class _StepCircle extends StatelessWidget {
  final int n; final bool done; final bool active;
  const _StepCircle({required this.n, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final Color bg = done ? _ink900 : active ? _accent : _line100;
    final Color fg = (done || active) ? Colors.white : _ink400;
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: done
          ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
          : Center(
              child: Text('$n',
                  style: TextStyle(
                      fontFamily: 'monospace', fontSize: 10,
                      fontWeight: FontWeight.w600, color: fg)),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.sans(
            fontSize: 11, weight: FontWeight.w500, color: _ink400),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTheme.sans(
            fontSize: 12, weight: FontWeight.w500, color: _ink600));
  }
}

class _Card extends StatelessWidget {
  final Widget child; final double padding;
  const _Card({required this.child, this.padding = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _ProductPicker extends StatelessWidget {
  final List<ProductItem> products;
  final ProductItem? selected;
  final ValueChanged<ProductItem> onSelect;
  const _ProductPicker(
      {required this.products, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: _line100,
          border: Border.all(color: _line200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text('Ürünler yükleniyor...',
              style: AppTheme.sans(fontSize: 13, color: _ink400)),
        ),
      );
    }
    return DropdownButtonFormField<ProductItem>(
      initialValue: selected,
      dropdownColor: Colors.white,
      style: AppTheme.sans(fontSize: 13, color: _ink900),
      iconEnabledColor: _ink400,
      decoration: InputDecoration(
        prefixIcon: const Icon(LucideIcons.package,
            size: 16, color: _ink400),
        filled: true, fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      hint: Text('Ürün seçin',
          style: AppTheme.sans(fontSize: 13, color: _ink400)),
      items: products
          .map((p) => DropdownMenuItem(
                value: p,
                child: Text('${p.name} (${p.sku})',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sans(fontSize: 13)),
              ))
          .toList(),
      onChanged: (v) { if (v != null) onSelect(v); },
    );
  }
}

class _UnitSegment extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _UnitSegment({required this.selected, required this.onSelect});

  static const _units = ['KG', 'PIECE', 'LITER', 'TON'];
  static const _labels = {'KG': 'kg', 'PIECE': 'adet', 'LITER': 'L', 'TON': 'ton'};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _line100, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: _units.map((u) {
          final active = u == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(u),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Center(
                  child: Text(_labels[u]!,
                      style: AppTheme.sans(
                          fontSize: 11,
                          weight: FontWeight.w600,
                          color: active ? _ink900 : _ink500)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool value, isLast;
  final VoidCallback onToggle;
  const _ToggleRow({
    required this.icon, required this.label, required this.sub,
    required this.value, required this.onToggle, required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: _line100))),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: value ? _accentSoft : _line100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17,
                color: value ? _accent : _ink500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.sans(
                        fontSize: 13,
                        weight: FontWeight.w600,
                        color: _ink900)),
                Text(sub,
                    style: AppTheme.sans(fontSize: 11, color: _ink500)),
              ],
            ),
          ),
          _IosSwitch(value: value),
        ]),
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
        color: value ? _accent : _line200,
        borderRadius: BorderRadius.circular(999)),
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
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String text; final String variant; final IconData? icon;
  const _PillTag(this.text, {this.variant = 'default', this.icon});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (variant) {
      case 'accent':  bg = _accentSoft;  fg = _accent;   break;
      case 'success': bg = _successSoft; fg = _success;  break;
      default:        bg = _line100;     fg = _ink700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(999),
        border: variant == 'default'
            ? Border.all(color: _line200)
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: fg), const SizedBox(width: 4),
        ],
        Text(text,
            style: AppTheme.sans(
                fontSize: 10, weight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

class _SummaryField extends StatelessWidget {
  final String label, value;
  const _SummaryField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTheme.sans(
                fontSize: 10, weight: FontWeight.w500, color: _ink400)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTheme.sans(
                fontSize: 13, weight: FontWeight.w600, color: _ink900)),
      ],
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String variant, label;
  final IconData? icon;
  final bool loading;
  const _FooterBtn({
    required this.onTap, required this.variant, required this.label,
    this.icon, this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    switch (variant) {
      case 'accent':    bg = _accent;  fg = Colors.white; border = _accent;  break;
      case 'secondary': bg = Colors.white; fg = _ink900; border = _line200;  break;
      default:          bg = _ink900;  fg = Colors.white; border = _ink900;
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? bg.withValues(alpha: 0.45) : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    if (label.isNotEmpty) const SizedBox(width: 8),
                  ],
                  if (label.isNotEmpty)
                    Text(label,
                        style: AppTheme.sans(
                            fontSize: 14,
                            weight: FontWeight.w600,
                            color: fg)),
                ]),
        ),
      ),
    );
  }
}
