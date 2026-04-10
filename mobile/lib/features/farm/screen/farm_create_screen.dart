import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/farm_bloc.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1976D2),
            surface: Color(0xFF0B1A33),
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
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Tarımsal Kayıt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
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
          final batches =
              state is FarmBatchesLoaded ? state.batches : <Map<String, dynamic>>[];
          final isLoading = state is FarmLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Batch Seç'),
                const SizedBox(height: 8),
                _batchDropdown(batches),
                const SizedBox(height: 20),

                _label('Tarla / Bahçe Konumu'),
                const SizedBox(height: 8),
                _inputField('örn. Muğla / Fethiye Tarla-3', _fieldCtrl,
                    TextInputType.text),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Ekim Tarihi'),
                        const SizedBox(height: 8),
                        _datePicker(context, true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Hasat Tarihi'),
                        const SizedBox(height: 8),
                        _datePicker(context, false),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                _label('Sulama Yöntemi'),
                const SizedBox(height: 8),
                _irrigationSelector(),
                const SizedBox(height: 12),
                _inputField('Toplam Sulama Süresi (saat)',
                    _irrigationHoursCtrl, TextInputType.number),
                const SizedBox(height: 20),

                _label('Kullanılan İlaçlar'),
                const SizedBox(height: 4),
                Text('Her satıra bir ilaç: Ad, Doz (ml/L), Son kullanım gün',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11)),
                const SizedBox(height: 8),
                _textArea(_pesticidesCtrl,
                    'örn. Fungisit X, 2.5 ml/L, 14 gün önce\nBöcek ilacı Y, 1.0 ml/L, 21 gün önce'),
                const SizedBox(height: 20),

                _label('Kullanılan Gübreler'),
                const SizedBox(height: 4),
                Text('Her satıra bir gübre: Ad, Miktar (kg/dekar)',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11)),
                const SizedBox(height: 8),
                _textArea(_fertilizersCtrl,
                    'örn. NPK 20-20-20, 5 kg/dekar\nÜre, 3 kg/dekar'),
                const SizedBox(height: 20),

                _label('Notlar'),
                const SizedBox(height: 8),
                _textArea(_notesCtrl, 'Ek gözlemler...'),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _submit(context, batches),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Kaydet',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500));

  Widget _batchDropdown(List<Map<String, dynamic>> batches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBatchId,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B1A33),
          hint: Text('Batch seçin',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          style: const TextStyle(color: Colors.white, fontSize: 14),
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

  Widget _datePicker(BuildContext context, bool isPlanting) {
    final date = isPlanting ? _plantingDate : _harvestDate;
    final label = date != null
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
        : 'Seç';
    return GestureDetector(
      onTap: () => _pickDate(context, isPlanting),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: date != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _irrigationSelector() {
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
                    ? const Color(0xFF1976D2).withValues(alpha: 0.2)
                    : const Color(0xFF0B1A33),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1976D2)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1),
              ),
              child: Text(t['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF42A5F5)
                          : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _inputField(
      String hint, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0B1A33),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _textArea(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0B1A33),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}
