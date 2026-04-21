import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/widgets/ibis_app_bar.dart';

class AdminUserCreateScreen extends StatelessWidget {
  const AdminUserCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(),
      child: const _CreateView(),
    );
  }
}

class _CreateView extends StatefulWidget {
  const _CreateView();
  @override
  State<_CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<_CreateView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRole = 'PRODUCER';
  bool _obscure = true;

  static const _roles = ['ADMIN', 'PRODUCER', 'INSPECTOR', 'LOGISTICS', 'WAREHOUSE', 'RETAILER', 'CUSTOMER'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad, email ve şifre zorunludur')));
      return;
    }
    context.read<AdminBloc>().add(CreateUser(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim(),
      role: _selectedRole,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Yeni Kullanıcı',
        accentColor: const Color(0xFF90A4AE),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is UserCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kullanıcı oluşturuldu'), backgroundColor: Color(0xFF2E7D32)));
            context.pop();
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final isLoading = state is AdminLoading;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _input(c, 'Ad Soyad', _nameCtrl),
                const SizedBox(height: 14),
                _input(c, 'Email', _emailCtrl, type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _passwordField(c),
                const SizedBox(height: 14),
                _input(c, 'Telefon (opsiyonel)', _phoneCtrl, type: TextInputType.phone),
                const SizedBox(height: 20),
                Text('Rol',
                    style: TextStyle(color: c.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                _roleSelector(c),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _input(IbisColors c, String hint, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _passwordField(IbisColors c) {
    return TextField(
      controller: _passCtrl,
      obscureText: _obscure,
      style: TextStyle(color: c.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Şifre',
        hintStyle: TextStyle(color: c.textDisabled, fontSize: 13),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
              color: c.textMuted, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  Widget _roleSelector(IbisColors c) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roles.map((role) {
        final isSelected = _selectedRole == role;
        return GestureDetector(
          onTap: () => setState(() => _selectedRole = role),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1976D2).withValues(alpha: 0.15)
                  : c.chipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF1976D2) : c.border,
              ),
            ),
            child: Text(role,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF42A5F5) : c.textMuted,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
          ),
        );
      }).toList(),
    );
  }
}
