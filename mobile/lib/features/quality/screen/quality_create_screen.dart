import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/quality_bloc.dart';

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
  final _notesCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _humCtrl = TextEditingController();

  String? _selectedBatchId;
  String _selectedResult = 'PASSED';
  bool _contamination = false;

  final _results = [
    {'value': 'PASSED', 'label': 'Geçti', 'color': const Color(0xFF66BB6A)},
    {'value': 'NEEDS_REVIEW', 'label': 'İnceleme Gerekli', 'color': const Color(0xFFFFB300)},
    {'value': 'FAILED', 'label': 'Başarısız', 'color': Colors.redAccent},
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    _tempCtrl.dispose();
    _humCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, List<Map<String, dynamic>> batches) {
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch seçiniz')));
      return;
    }
    context.read<QualityBloc>().add(CreateCheck(
      batchId: _selectedBatchId!,
      result: _selectedResult,
      temperature: _tempCtrl.text.isEmpty ? null : double.tryParse(_tempCtrl.text),
      humidity: _humCtrl.text.isEmpty ? null : double.tryParse(_humCtrl.text),
      contaminationDetected: _contamination,
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
        title: const Text('Yeni Kontrol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<QualityBloc, QualityState>(
        listener: (context, state) {
          if (state is CheckCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kontrol kaydedildi'), backgroundColor: Color(0xFF2E7D32)));
            context.pop();
          }
          if (state is QualityError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final batches = state is BatchesLoaded ? state.batches : <Map<String, dynamic>>[];
          final isLoading = state is QualityLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Batch Seç'),
                const SizedBox(height: 8),
                _dropdown(batches),
                const SizedBox(height: 20),
                _label('Kontrol Sonucu'),
                const SizedBox(height: 8),
                _resultSelector(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _inputField('Sıcaklık (°C)', _tempCtrl, TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField('Nem (%)', _humCtrl, TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 20),
                _label('Kirlilik Tespit Edildi'),
                const SizedBox(height: 8),
                _contaminationToggle(),
                const SizedBox(height: 20),
                _label('Notlar'),
                const SizedBox(height: 8),
                _textArea(),
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
                        : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500));

  Widget _dropdown(List<Map<String, dynamic>> batches) {
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
          hint: Text('Batch seçin', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: batches.map((b) => DropdownMenuItem<String>(
            value: b['id'].toString(),
            child: Text('${b['batchCode']} — ${b['productName']}',
                overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) => setState(() => _selectedBatchId = v),
        ),
      ),
    );
  }

  Widget _resultSelector() {
    return Row(
      children: _results.map((r) {
        final isSelected = _selectedResult == r['value'];
        final color = r['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedResult = r['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF0B1A33),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.1), width: isSelected ? 1.5 : 1),
              ),
              child: Text(r['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isSelected ? color : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0B1A33),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _contaminationToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Kirlilik var', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Switch(
            value: _contamination,
            onChanged: (v) => setState(() => _contamination = v),
            activeThumbColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _textArea() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Gözlemlerinizi yazın...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0B1A33),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}
