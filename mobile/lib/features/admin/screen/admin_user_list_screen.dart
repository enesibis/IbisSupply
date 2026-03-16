import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/admin_bloc.dart';
import '../model/user_model.dart';

class AdminUserListScreen extends StatelessWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc()..add(LoadUsers()),
      child: const _AdminUserListView(),
    );
  }
}

class _AdminUserListView extends StatelessWidget {
  const _AdminUserListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Kullanıcı Yönetimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminBloc>().add(LoadUsers()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/users/create'),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is UsersLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.users.length,
              itemBuilder: (_, i) => _UserCard(user: state.users[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserResponse user;
  const _UserCard({required this.user});

  Color get _roleColor {
    switch (user.role) {
      case 'ADMIN': return const Color(0xFFE53935);
      case 'PRODUCER': return const Color(0xFF43A047);
      case 'INSPECTOR': return const Color(0xFFFF8F00);
      case 'LOGISTICS': return const Color(0xFF9C27B0);
      case 'WAREHOUSE': return const Color(0xFF00ACC1);
      case 'RETAILER': return const Color(0xFF1976D2);
      default: return Colors.grey;
    }
  }

  void _showOptions(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1A33),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _UserOptionsSheet(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.active ? Colors.white.withValues(alpha: 0.07) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _roleColor.withValues(alpha: 0.2),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(color: _roleColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.fullName,
                        style: TextStyle(
                          color: user.active ? Colors.white : Colors.white38,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    if (!user.active) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Pasif',
                            style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(user.email,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(user.role,
                    style: TextStyle(color: _roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showOptions(context),
                child: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.4), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserOptionsSheet extends StatelessWidget {
  final UserResponse user;
  const _UserOptionsSheet({required this.user});

  static const _roles = ['ADMIN', 'PRODUCER', 'INSPECTOR', 'LOGISTICS', 'WAREHOUSE', 'RETAILER', 'CUSTOMER', 'NONE'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.fullName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(user.email,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          const SizedBox(height: 20),
          const Text('Rol Değiştir',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roles.map((role) {
              final isSelected = user.role == role;
              return GestureDetector(
                onTap: () {
                  context.read<AdminBloc>().add(UpdateRole(userId: user.id, role: role));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1976D2).withValues(alpha: 0.3)
                        : const Color(0xFF0D2040),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1976D2)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(role,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF42A5F5) : Colors.white60,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AdminBloc>().add(ToggleActive(user.id));
                Navigator.pop(context);
              },
              icon: Icon(user.active ? Icons.block : Icons.check_circle_outline,
                  color: user.active ? Colors.redAccent : const Color(0xFF66BB6A)),
              label: Text(
                user.active ? 'Hesabı Devre Dışı Bırak' : 'Hesabı Aktifleştir',
                style: TextStyle(color: user.active ? Colors.redAccent : const Color(0xFF66BB6A)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: user.active
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : const Color(0xFF66BB6A).withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
