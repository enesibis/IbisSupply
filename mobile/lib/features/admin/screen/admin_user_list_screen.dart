import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/admin_bloc.dart';
import '../model/user_model.dart';


import '../../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Kullanıcı Yönetimi',
          style: AppTheme.sans(fontSize: 15, weight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw,
                color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<AdminBloc>().add(LoadUsers()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4E4E7)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/users/create'),
        label: Text('Yeni Kullanıcı', style: AppTheme.sans(weight: FontWeight.w600, color: Colors.white)),
        icon: Icon(LucideIcons.userPlus, size: 18, color: Colors.white),
        backgroundColor: AppTheme.ink,
        foregroundColor: Colors.white,
        elevation: 2,
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2), strokeWidth: 2));
          }
          if (state is UsersLoaded) {
            if (state.users.isEmpty) {
              return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(LucideIcons.users, size: 24, color: const Color(0xFFA1A1AA)),
                ),
                const SizedBox(height: 16),
                Text('Kullanıcı bulunamadı',
                    style: AppTheme.sans(fontSize: 15, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Yeni kullanıcı eklemek için\nsağ alttaki butona bas.',
                    style: AppTheme.sans(fontSize: 13, color: const Color(0xFF71717A)),
                    textAlign: TextAlign.center),
              ],
            ),
          );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
      case 'ADMIN':     return const Color(0xFFE53935);
      case 'PRODUCER':  return const Color(0xFF43A047);
      case 'INSPECTOR': return const Color(0xFFFF8F00);
      case 'LOGISTICS': return const Color(0xFF9C27B0);
      case 'WAREHOUSE': return const Color(0xFF00ACC1);
      case 'RETAILER':  return const Color(0xFF1976D2);
      default:          return Colors.grey;
    }
  }

  void _showOptions(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.active ? const Color(0xFFE4E4E7) : Colors.red.withValues(alpha: 0.35),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _roleColor.withValues(alpha: 0.15),
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
                    Flexible(
                      child: Text(user.fullName,
                          style: TextStyle(
                            color: user.active ? AppTheme.ink : const Color(0xFFA1A1AA),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (!user.active) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
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
                    style: TextStyle(color: const Color(0xFFA1A1AA), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(user.role,
                    style: TextStyle(color: _roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showOptions(context),
                child: Icon(LucideIcons.moreVertical, color: const Color(0xFFD4D4D8), size: 20),
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
              style: TextStyle(color: AppTheme.ink, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(user.email,
              style: TextStyle(color: const Color(0xFFA1A1AA), fontSize: 13)),
          const SizedBox(height: 20),
          Text('Rol Değiştir',
              style: TextStyle(color: const Color(0xFF71717A), fontSize: 13, fontWeight: FontWeight.w600)),
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
                        ? const Color(0xFF1976D2).withValues(alpha: 0.15)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1976D2)
                          : const Color(0xFFE4E4E7),
                    ),
                  ),
                  child: Text(role,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF42A5F5) : const Color(0xFFA1A1AA),
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
              icon: Icon(user.active ? LucideIcons.ban : LucideIcons.checkCircle2,
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
