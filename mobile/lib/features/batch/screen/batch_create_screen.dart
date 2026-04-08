import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/batch_bloc.dart';
import '../model/batch_model.dart';

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
  final _formKey = GlobalKey<FormState>();
  ProductItem? _selectedProduct;
  final _quantityCtrl = TextEditingController();
  String _unit = 'KG';
  DateTime _productionDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 90));
  final _locationCtrl = TextEditingController();
  List<ProductItem> _products = [];

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isProduction) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isProduction ? _productionDate : _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
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
        if (isProduction) _productionDate = picked;
        else _expiryDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedProduct == null) {
        _snack('Ürün seçiniz');
        return;
      }
      context.read<BatchBloc>().add(CreateBatch(
        productId: _selectedProduct!.id,
        quantity: double.parse(_quantityCtrl.text),
        unit: _unit,
        productionDate: _productionDate.toIso8601String().split('T').first,
        expiryDate: _expiryDate.toIso8601String().split('T').first,
        originLocation: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
      ));
    }
  }

  void _snack(String msg, {Color color = const Color(0xFF1976D2)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        title: const Text('Yeni Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<BatchBloc, BatchState>(
        listener: (context, state) {
          if (state is ProductsLoaded) setState(() => _products = state.products);
          if (state is BatchCreated) {
            _snack('Batch oluşturuldu: ${state.batch.batchCode}', color: const Color(0xFF2E7D32));
            Navigator.pop(context, true);
          }
          if (state is BatchError) _snack(state.message, color: Colors.redAccent);
        },
        builder: (context, state) {
          if (state is BatchLoading && _products.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _DarkCard(
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF42A5F5),
                    title: 'Ürün Bilgileri',
                    child: Column(
                      children: [
                        _DarkDropdown<ProductItem>(
                          hint: 'Ürün seçin',
                          value: _selectedProduct,
                          items: _products.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (${p.sku})', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() {
                            _selectedProduct = v;
                            if (v != null) _unit = v.unit;
                          }),
                          validator: (v) => v == null ? 'Ürün seçiniz' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            flex: 2,
                            child: _DarkField(
                              controller: _quantityCtrl,
                              hint: 'Miktar',
                              icon: Icons.scale_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Gerekli';
                                if (double.tryParse(v) == null) return 'Sayı girin';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DarkDropdown<String>(
                              hint: 'Birim',
                              value: _unit,
                              items: ['KG', 'PIECE', 'LITER', 'TON']
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) => setState(() => _unit = v!),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _DarkField(
                          controller: _locationCtrl,
                          hint: 'Menşei / Konum (opsiyonel)',
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkCard(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFFFFB74D),
                    title: 'Tarih Bilgileri',
                    child: Column(children: [
                      _DateRow(
                        label: 'Üretim Tarihi',
                        date: _productionDate,
                        onTap: () => _pickDate(true),
                      ),
                      Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                      _DateRow(
                        label: 'Son Kullanma Tarihi',
                        date: _expiryDate,
                        onTap: () => _pickDate(false),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<BatchBloc, BatchState>(
                      builder: (context, state) {
                        final loading = state is BatchLoading;
                        return GestureDetector(
                          onTap: loading ? null : _submit,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: loading
                                  ? LinearGradient(colors: [
                                      const Color(0xFF1565C0).withValues(alpha: 0.4),
                                      const Color(0xFF1565C0).withValues(alpha: 0.4),
                                    ])
                                  : const LinearGradient(
                                      colors: [Color(0xFF1976D2), Color(0xFF1E88E5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: loading ? [] : [
                                BoxShadow(
                                  color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: loading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Batch Oluştur',
                                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                    ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Dark kart ─────────────────────────────────────────────────────────────────
class _DarkCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _DarkCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: iconColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dark input ────────────────────────────────────────────────────────────────
class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 20) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Dark dropdown ─────────────────────────────────────────────────────────────
class _DarkDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _DarkDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF0D1F3C),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      iconEnabledColor: Colors.white38,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// ── Tarih satırı ──────────────────────────────────────────────────────────────
class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateRow({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, color: Colors.white.withValues(alpha: 0.4), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              const SizedBox(height: 2),
              Text('${date.day}.${date.month}.${date.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ),
          Icon(Icons.edit_outlined, size: 16, color: Colors.white.withValues(alpha: 0.25)),
        ]),
      ),
    );
  }
}
