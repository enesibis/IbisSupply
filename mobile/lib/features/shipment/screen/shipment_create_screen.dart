import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../batch/bloc/batch_bloc.dart';
import '../../batch/model/batch_model.dart';

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
  final _formKey = GlobalKey<FormState>();
  BatchResponse? _selectedBatch;
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<BatchResponse> _batches = [];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _plateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedBatch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch seçiniz')),
        );
        return;
      }
      context.read<ShipmentBloc>().add(CreateShipment(
            batchId: _selectedBatch!.id,
            fromLocation: _fromCtrl.text.trim(),
            toLocation: _toCtrl.text.trim(),
            vehiclePlate: _plateCtrl.text.trim().isEmpty ? null : _plateCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Yeni Sevkiyat')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BatchBloc, BatchState>(
            listener: (context, state) {
              if (state is BatchListLoaded) {
                setState(() => _batches = state.batches);
              }
            },
          ),
          BlocListener<ShipmentBloc, ShipmentState>(
            listener: (context, state) {
              if (state is ShipmentCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sevkiyat oluşturuldu: ${state.shipment.shipmentCode}'),
                    backgroundColor: AppTheme.success,
                  ),
                );
                Navigator.pop(context, true);
              }
              if (state is ShipmentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ShipmentBloc, ShipmentState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Batch Seçimi',
                      child: BlocBuilder<BatchBloc, BatchState>(
                        builder: (context, batchState) {
                          if (batchState is BatchLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return DropdownButtonFormField<BatchResponse>(
                            value: _selectedBatch,
                            decoration: const InputDecoration(
                              labelText: 'Batch',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            items: _batches.map((b) => DropdownMenuItem(
                              value: b,
                              child: Text('${b.productName} - ${b.batchCode}',
                                  overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedBatch = v),
                            validator: (v) => v == null ? 'Batch seçiniz' : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Güzergah',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fromCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Çıkış Noktası',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Çıkış noktası gerekli' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _toCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Varış Noktası',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Varış noktası gerekli' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Araç Bilgileri',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _plateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Plaka (opsiyonel)',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Notlar (opsiyonel)',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state is ShipmentLoading ? null : _submit,
                        icon: state is ShipmentLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.local_shipping_rounded),
                        label: const Text('Sevkiyat Oluştur'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
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
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
