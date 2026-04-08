import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shipment_bloc.dart';
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
        _snack('Batch seçiniz');
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
        title: const Text('Yeni Sevkiyat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BatchBloc, BatchState>(
            listener: (context, state) {
              if (state is BatchListLoaded) setState(() => _batches = state.batches);
            },
          ),
          BlocListener<ShipmentBloc, ShipmentState>(
            listener: (context, state) {
              if (state is ShipmentCreated) {
                _snack('Sevkiyat oluşturuldu: ${state.shipment.shipmentCode}',
                    color: const Color(0xFF2E7D32));
                Navigator.pop(context, true);
              }
              if (state is ShipmentError) _snack(state.message, color: Colors.redAccent);
            },
          ),
        ],
        child: BlocBuilder<ShipmentBloc, ShipmentState>(
          builder: (context, state) {
            final loading = state is ShipmentLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Batch seçimi
                    _DarkCard(
                      icon: Icons.inventory_2_rounded,
                      iconColor: const Color(0xFF42A5F5),
                      title: 'Batch Seçimi',
                      child: BlocBuilder<BatchBloc, BatchState>(
                        builder: (context, batchState) {
                          if (batchState is BatchLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                              ),
                            );
                          }
                          return _DarkDropdown<BatchResponse>(
                            hint: 'Batch seçin',
                            value: _selectedBatch,
                            items: _batches.map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(
                                '${b.productName} — ${b.batchCode}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedBatch = v),
                            validator: (v) => v == null ? 'Batch seçiniz' : null,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Güzergah
                    _DarkCard(
                      icon: Icons.route_rounded,
                      iconColor: const Color(0xFFCE93D8),
                      title: 'Güzergah',
                      child: Column(children: [
                        _DarkField(
                          controller: _fromCtrl,
                          hint: 'Çıkış Noktası',
                          icon: Icons.location_on_outlined,
                          validator: (v) => (v == null || v.isEmpty) ? 'Gerekli' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.arrow_downward_rounded,
                              color: Colors.white.withValues(alpha: 0.2), size: 18),
                        ]),
                        const SizedBox(height: 12),
                        _DarkField(
                          controller: _toCtrl,
                          hint: 'Varış Noktası',
                          icon: Icons.flag_outlined,
                          validator: (v) => (v == null || v.isEmpty) ? 'Gerekli' : null,
                        ),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // Araç bilgileri
                    _DarkCard(
                      icon: Icons.local_shipping_rounded,
                      iconColor: const Color(0xFF66BB6A),
                      title: 'Araç Bilgileri',
                      child: Column(children: [
                        _DarkField(
                          controller: _plateCtrl,
                          hint: 'Plaka (opsiyonel)',
                          icon: Icons.directions_car_outlined,
                        ),
                        const SizedBox(height: 12),
                        _DarkField(
                          controller: _notesCtrl,
                          hint: 'Notlar (opsiyonel)',
                          icon: Icons.notes_outlined,
                          maxLines: 2,
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // Buton
                    GestureDetector(
                      onTap: loading ? null : _submit,
                      child: Container(
                        height: 52,
                        width: double.infinity,
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
                                  Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Sevkiyat Oluştur',
                                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                ]),
                        ),
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
  final int maxLines;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
