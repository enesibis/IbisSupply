import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/customer_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ComplaintScreen extends StatelessWidget {
  final String? prefillBatchCode;
  const ComplaintScreen({super.key, this.prefillBatchCode});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerBloc(),
      child: _ComplaintView(prefillBatchCode: prefillBatchCode),
    );
  }
}

class _ComplaintView extends StatefulWidget {
  final String? prefillBatchCode;
  const _ComplaintView({this.prefillBatchCode});

  @override
  State<_ComplaintView> createState() => _ComplaintViewState();
}

class _ComplaintViewState extends State<_ComplaintView> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late final TextEditingController _batchCtrl;
  String _category = 'Kalite Sorunu';

  static const _categories = [
    'Kalite Sorunu', 'Soğuk Zincir İhlali', 'Etiket Hatası',
    'Son Kullanma Tarihi', 'Paketleme Hasarı', 'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _batchCtrl = TextEditingController(text: widget.prefillBatchCode ?? '');
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<CustomerBloc>().add(SubmitComplaint(
        subject: '$_category: ${_subjectCtrl.text.trim()}',
        description: _descCtrl.text.trim(),
        batchCode: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is ComplaintSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Şikayetiniz alındı, en kısa sürede incelenecektir.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ));
          context.pop();
        }
        if (state is CustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Şikayet Bildir',
          style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4E4E7)),
        ),
      ),
        body: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            final loading = state is CustomerLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _SectionCard(
                      icon: LucideIcons.tag,
                      iconColor: const Color(0xFFCE93D8),
                      title: 'Şikayet Kategorisi',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final selected = _category == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _category = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF7B1FA2).withValues(alpha: 0.18)
                                    : const Color(0xFFF4F4F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? const Color(0xFFCE93D8) : const Color(0xFFE4E4E7),
                                ),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                    color: selected ? const Color(0xFFCE93D8) : const Color(0xFFA1A1AA),
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _SectionCard(
                      icon: LucideIcons.fileEdit,
                      iconColor: const Color(0xFF42A5F5),
                      title: 'Şikayet Detayı',
                      child: Column(
                        children: [
                          _IbisField(
                            controller: _subjectCtrl,
                            hint: 'Konu başlığı',
                            icon: LucideIcons.type,
                            validator: (v) => (v == null || v.isEmpty) ? 'Konu gerekli' : null,
                          ),
                          const SizedBox(height: 12),
                          _IbisField(
                            controller: _batchCtrl,
                            hint: 'Batch kodu (opsiyonel)',
                            icon: LucideIcons.qrCode,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            style: TextStyle(color: AppTheme.ink, fontSize: 14),
                            validator: (v) => (v == null || v.isEmpty) ? 'Açıklama gerekli' : null,
                            decoration: InputDecoration(
                              hintText: 'Sorunu detaylı açıklayın...',
                              hintStyle: TextStyle(color: const Color(0xFFD4D4D8), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFF4F4F5),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: const Color(0xFFE4E4E7))),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: const Color(0xFFE4E4E7))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5)),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFEF5350))),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFEF5350))),
                              errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

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
                          boxShadow: loading
                              ? []
                              : [BoxShadow(
                                  color: const Color(0xFF1976D2).withValues(alpha: 0.35),
                                  blurRadius: 16, offset: const Offset(0, 5))],
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(LucideIcons.send, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Şikayet Gönder',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon, required this.iconColor,
    required this.title, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: false
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(color: iconColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          Divider(height: 1, color: const Color(0xFFE4E4E7)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IbisField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? Function(String?)? validator;

  const _IbisField({
    required this.controller, required this.hint,
    this.icon, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: AppTheme.ink, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFFD4D4D8), fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFA1A1AA), size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFE4E4E7))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFE4E4E7))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5350))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5350))),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
