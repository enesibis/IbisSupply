import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/quality_bloc.dart';
import '../model/quality_check_model.dart';
import '../../../core/widgets/ibis_app_bar.dart';
import '../../../core/widgets/ibis_list_tile.dart';
import '../../../core/theme/ibis_colors.dart';

class QualityListScreen extends StatelessWidget {
  const QualityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QualityBloc()..add(LoadMyChecks()),
      child: const _QualityListView(),
    );
  }
}

class _QualityListView extends StatelessWidget {
  const _QualityListView();

  void _confirmDelete(BuildContext context, QualityCheckResponse check) {
    final c = IbisColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kaydı Sil',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('${check.productName} kalite kontrol kaydı silinecek. Emin misiniz?',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<QualityBloc>().add(DeleteCheck(check.id));
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Kalite Kontrol',
        accentColor: const Color(0xFFFFB74D),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<QualityBloc>().add(LoadMyChecks()),
          ),
        ],
      ),
      floatingActionButton: IbisFab(
        onPressed: () => context.push('/quality-checks/create'),
        icon: Icons.add_rounded,
        label: 'Yeni Kontrol',
        colors: const [Color(0xFFE65100), Color(0xFFFB8C00)],
      ),
      body: BlocConsumer<QualityBloc, QualityState>(
        listener: (context, state) {
          if (state is CheckDeleted) {
            context.read<QualityBloc>().add(LoadMyChecks());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kayıt silindi'),
              backgroundColor: Color(0xFF455A64),
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is QualityError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is QualityLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB74D), strokeWidth: 2));
          }
          if (state is QualityError) {
            return IbisErrorState(
              message: state.message,
              onRetry: () => context.read<QualityBloc>().add(LoadMyChecks()),
            );
          }
          if (state is ChecksLoaded) {
            if (state.checks.isEmpty) {
              return const IbisEmptyState(
                icon: Icons.verified_outlined,
                title: 'Henüz kontrol kaydı yok',
                subtitle: 'Kalite kontrolü eklemek için\nsağ alttaki butona bas.',
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
              itemCount: state.checks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _CheckCard(
                check: state.checks[i],
                onDelete: () => _confirmDelete(ctx, state.checks[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final QualityCheckResponse check;
  final VoidCallback onDelete;
  const _CheckCard({required this.check, required this.onDelete});

  Color get _color {
    switch (check.result) {
      case 'PASSED': return const Color(0xFF66BB6A);
      case 'FAILED': return const Color(0xFFEF5350);
      case 'NEEDS_REVIEW': return const Color(0xFFFFB300);
      default: return Colors.grey;
    }
  }

  String get _label {
    switch (check.result) {
      case 'PASSED': return 'Geçti';
      case 'FAILED': return 'Başarısız';
      case 'NEEDS_REVIEW': return 'İnceleme Gerekli';
      default: return check.result;
    }
  }

  IconData get _icon {
    switch (check.result) {
      case 'PASSED': return Icons.check_circle_rounded;
      case 'FAILED': return Icons.cancel_rounded;
      default: return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return IbisListTile(
      accentColor: _color,
      icon: Icon(_icon, color: _color, size: 22),
      title: Text(check.productName,
          style: TextStyle(color: c.text, fontWeight: FontWeight.w700,
              fontSize: 15, letterSpacing: -0.1)),
      subtitle: Text(check.batchCode,
          style: TextStyle(color: c.textMuted, fontSize: 11,
              fontFamily: 'monospace', letterSpacing: 0.5)),
      badge: Row(
        children: [
          IbisStatusBadge(label: _label, color: _color),
          if (check.notes != null && check.notes!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(check.notes!,
                  style: TextStyle(color: c.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.withValues(alpha: 0.7), size: 15),
            ),
          ),
        ],
      ),
    );
  }
}
