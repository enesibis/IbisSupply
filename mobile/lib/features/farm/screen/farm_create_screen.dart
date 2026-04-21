import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/farm_bloc.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/widgets/ibis_app_bar.dart';

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
  final _fieldCtrl = TextEditingController();
  final _irrigationHoursCtrl = TextEditingController();
  final _pesticidesCtrl = TextEditingController();
  final _fertilizersCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedBatchId;
  String _irrigationType = 'DRIP';
  DateTime? _plantingDate;
  DateTime? _harvestDate;

  final _irrigationTypes = [
    {'value': 'DRIP', 'label': 'Damla'},
    {'value': 'SPRINKLER', 'label': 'Yağmurlama'},
    {'value': 'FLOOD', 'label': 'Taşkın'},
    {'value': 'MANUAL', 'label': 'Manuel'},
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

  Future<void> _pickDate(BuildContext context, bool isPlanting) async {
    final c = IbisColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: c.isDark
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF1976D2),
                  surface: Color(0xFF0B1A33),
                ),
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1976D2),
                ),
              ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isPlanting) {
          _plantingDate = picked;
        } else {
          _harvestDate = picked;
        }
      });
    }
  }

  void _submit(BuildContext context, List<Map<String, dynamic>> batches) {
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch seçiniz')));
      return;
    }
    context.read<FarmBloc>().add(CreateFarmRecord(
      batchId: _selectedBatchId!,
      fieldLocation: _fieldCtrl.text.isEmpty ? null : _fieldCtrl.text,
      plantingDate: _plantingDate?.toIso8601String().substring(0, 10),
      harvestDate: _harvestDate?.toIso8601String().substring(0, 10),
      irrigationType: _irrigationType,
      totalIrrigationHours: _irrigationHoursCtrl.text.isEmpty
          ? null
          : double.tryParse(_irrigationHoursCtrl.text),
      pesticides: _pesticidesCtrl.text.isEmpty ? null : _pesticidesCtrl.text,
      fertilizers: _fertilizersCtrl.text.isEmpty ? null : _fertilizersCtrl.text,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Tarımsal Kayıt',
        accentColor: const Color(0xFF66BB6A),
      ),
      body: BlocConsumer<FarmBloc, FarmState>(
        listener: (context, state) {
          if (state is FarmRecordCreated) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Kayıt oluşturuldu'),
                backgroundColor: Color(0xFF2E7D32)));
            context.pop();
          }
          if (state is FarmError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final batches = state is FarmBatchesLoaded ? state.batches : <Map<String, dynamic>>[];
          final isLoading = state is FarmLoading;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(c, 'Batch Seç'),
                const SizedBox(height: 8),
                _batchDropdown(c, batches),
                const SizedBox(height: 20),

                _label(c, 'Tarla / Bahçe Konumu'),
                const SizedBox(height: 8),
                _inputField(c, 'örn. Muğla / Fethiye Tarla-3', _fieldCtrl, TextInputType.text),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(c, 'Ekim Tarihi'),
                        const SizedBox(height: 8),
                        _datePicker(c, context, true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(c, 'Hasat Tarihi'),
                        const SizedBox(height: 8),
                        _datePicker(c, context, false),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                _label(c, 'Sulama Yöntemi'),
                const SizedBox(height: 8),
                _irrigationSelector(c),
                const SizedBox(height: 12),
                _inputField(c, 'Toplam Sulama Süresi (saat)', _irrigationHoursCtrl, TextInputType.number),
                const SizedBox(height: 20),

                _label(c, 'Kullanılan İlaçlar'),
                const SizedBox(height: 4),
                Text('Her satıra bir ilaç: Ad, Doz (ml/L), Son kullanım gün',
                    style: TextStyle(color: c.textDisabled, fontSize: 11)),
                const SizedBox(height: 8),
                _textArea(c, _pesticidesCtrl,
                    'örn. Fungisit X, 2.5 ml/L, 14 gün önce\nBöcek ilacı Y, 1.0 ml/L, 21 gün önce'),
                const SizedBox(height: 20),

                _label(c, 'Kullanılan Gübreler'),
                const SizedBox(height: 4),
                Text('Her satıra bir gübre: Ad, Miktar (kg/dekar)',
                    style: TextStyle(color: c.textDisabled, fontSize: 11)),
                const SizedBox(height: 8),
                _textArea(c, _fertilizersCtrl, 'örn. NPK 20-20-20, 5 kg/dekar\nÜre, 3 kg/dekar'),
                const SizedBox(height: 20),

                _label(c, 'Notlar'),
                const SizedBox(height: 8),
                _textArea(c, _notesCtrl, 'Ek gözlemler...'),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _submit(context, batches),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Kaydet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(IbisColors c, String text) => Text(text,
      style: TextStyle(color: c.textMuted, fontSize: 13, fontWeight: FontWeight.w500));

  Widget _batchDropdown(IbisColors c, List<Map<String, dynamic>> batches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBatchId,
          isExpanded: true,
          dropdownColor: c.surface,
          hint: Text('Batch seçin', style: TextStyle(color: c.textDisabled)),
          style: TextStyle(color: c.text, fontSize: 14),
          items: batches
              .map((b) => DropdownMenuItem<String>(
                    value: b['id'].toString(),
                    child: Text('${b['batchCode']} — ${b['productName']}',
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedBatchId = v),
        ),
      ),
    );
  }

  Widget _datePicker(IbisColors c, BuildContext context, bool isPlanting) {
    final date = isPlanting ? _plantingDate : _harvestDate;
    final label = date != null
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
        : 'Seç';
    return GestureDetector(
      onTap: () => _pickDate(context, isPlanting),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: c.textMuted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: date != null ? c.text : c.textDisabled, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _irrigationSelector(IbisColors c) {
    return Row(
      children: _irrigationTypes.map((t) {
        final isSelected = _irrigationType == t['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _irrigationType = t['value']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1976D2).withValues(alpha: 0.15)
                    : c.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? const Color(0xFF1976D2) : c.border,
                    width: isSelected ? 1.5 : 1),
              ),
              child: Text(t['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected ? const Color(0xFF42A5F5) : c.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _inputField(IbisColors c, String hint, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(color: c.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textDisabled, fontSize: 13),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _textArea(IbisColors c, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      style: TextStyle(color: c.text, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textDisabled, fontSize: 12),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}
