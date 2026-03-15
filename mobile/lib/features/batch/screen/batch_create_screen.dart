import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/batch_bloc.dart';
import '../model/batch_model.dart';
import '../../../core/theme/app_theme.dart';

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
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün seçiniz')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Yeni Batch Oluştur')),
      body: BlocConsumer<BatchBloc, BatchState>(
        listener: (context, state) {
          if (state is ProductsLoaded) {
            setState(() => _products = state.products);
          }
          if (state is BatchCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Batch oluşturuldu: ${state.batch.batchCode}'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pop(context, true);
          }
          if (state is BatchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is BatchLoading && _products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Ürün Bilgileri',
                    child: Column(
                      children: [
                        // Ürün seç
                        DropdownButtonFormField<ProductItem>(
                          value: _selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Ürün',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _products.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (${p.sku})'),
                          )).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedProduct = v;
                              if (v != null) _unit = v.unit;
                            });
                          },
                          validator: (v) => v == null ? 'Ürün seçiniz' : null,
                        ),
                        const SizedBox(height: 16),

                        // Miktar + birim
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _quantityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Miktar',
                                  prefixIcon: Icon(Icons.scale_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Miktar gerekli';
                                  if (double.tryParse(v) == null) return 'Geçerli sayı girin';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _unit,
                                decoration: const InputDecoration(labelText: 'Birim'),
                                items: ['KG', 'PIECE', 'LITER', 'TON']
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) => setState(() => _unit = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Konum
                        TextFormField(
                          controller: _locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Menşei / Konum (opsiyonel)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Tarih Bilgileri',
                    child: Column(
                      children: [
                        _DateTile(
                          label: 'Üretim Tarihi',
                          date: _productionDate,
                          onTap: () => _pickDate(true),
                        ),
                        const Divider(height: 1),
                        _DateTile(
                          label: 'Son Kullanma Tarihi',
                          date: _expiryDate,
                          onTap: () => _pickDate(false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  BlocBuilder<BatchBloc, BatchState>(
                    builder: (context, state) {
                      return ElevatedButton.icon(
                        onPressed: state is BatchLoading ? null : _submit,
                        icon: state is BatchLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Batch Oluştur'),
                      );
                    },
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(
        '${date.day}.${date.month}.${date.year}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}
