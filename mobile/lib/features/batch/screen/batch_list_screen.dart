import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/batch_bloc.dart';
import '../model/batch_model.dart';
import '../../../core/widgets/ibis_app_bar.dart';
import '../../../core/widgets/ibis_list_tile.dart';
import '../../../core/theme/ibis_colors.dart';
import 'batch_create_screen.dart';
import 'batch_detail_screen.dart';

class BatchListScreen extends StatelessWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BatchBloc()..add(LoadBatches()),
      child: const _BatchListView(),
    );
  }
}

class _BatchListView extends StatelessWidget {
  const _BatchListView();

  void _confirmDelete(BuildContext context, BatchResponse batch) {
    final c = IbisColors.of(context);
    if (batch.status != 'CREATED') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sadece CREATED statüsündeki batch\'ler silinebilir'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batch\'i Sil',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('${batch.productName} batch\'i kalıcı olarak silinecek. Emin misiniz?',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BatchBloc>().add(DeleteBatch(batch.id));
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
        title: 'Batch Yönetimi',
        accentColor: const Color(0xFF66BB6A),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<BatchBloc>().add(LoadBatches()),
          ),
        ],
      ),
      floatingActionButton: IbisFab(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const BatchCreateScreen()),
          );
          if (created == true && context.mounted) {
            context.read<BatchBloc>().add(LoadBatches());
          }
        },
        icon: Icons.add_rounded,
        label: 'Yeni Batch',
        colors: const [Color(0xFF2E7D32), Color(0xFF43A047)],
      ),
      body: BlocConsumer<BatchBloc, BatchState>(
        listener: (context, state) {
          if (state is BatchDeleted) {
            context.read<BatchBloc>().add(LoadBatches());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Batch silindi'),
              backgroundColor: Color(0xFF455A64),
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is BatchError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is BatchLoading) return const _LoadingView();
          if (state is BatchError) {
            return IbisErrorState(
              message: state.message,
              onRetry: () => context.read<BatchBloc>().add(LoadBatches()),
            );
          }
          if (state is BatchListLoaded) {
            if (state.batches.isEmpty) {
              return const IbisEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Henüz batch yok',
                subtitle: 'Yeni bir üretim partisi oluşturmak için\nsağ alttaki butona bas.',
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
              itemCount: state.batches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _BatchCard(
                batch: state.batches[i],
                onDelete: () => _confirmDelete(context, state.batches[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 82,
        decoration: BoxDecoration(
          color: c.isDark ? null : Colors.white,
          gradient: c.isDark
              ? LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.04 + _anim.value * 0.03),
                  Colors.white.withValues(alpha: 0.02),
                ])
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final BatchResponse batch;
  final VoidCallback onDelete;
  const _BatchCard({required this.batch, required this.onDelete});

  static const _statusColors = {
    'CREATED': Color(0xFF42A5F5),
    'IN_TRANSIT': Color(0xFFCE93D8),
    'IN_WAREHOUSE': Color(0xFF66BB6A),
    'SOLD': Color(0xFF4DB6AC),
    'RECALLED': Color(0xFFEF5350),
  };

  static const _statusLabels = {
    'CREATED': 'Oluşturuldu',
    'IN_TRANSIT': 'Taşımada',
    'IN_WAREHOUSE': 'Depoda',
    'SOLD': 'Satıldı',
    'RECALLED': 'Geri Çağrıldı',
  };

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final color = _statusColors[batch.status] ?? const Color(0xFF42A5F5);

    return IbisListTile(
      accentColor: color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailScreen(batch: batch)),
      ),
      icon: Icon(Icons.inventory_2_rounded, color: color, size: 22),
      title: Text(batch.productName,
          style: TextStyle(color: c.text, fontWeight: FontWeight.w700,
              fontSize: 15, letterSpacing: -0.1)),
      subtitle: Text(batch.batchCode,
          style: TextStyle(color: c.textMuted, fontSize: 11,
              fontFamily: 'monospace', letterSpacing: 0.5)),
      badge: Row(
        children: [
          IbisStatusBadge(label: _statusLabels[batch.status] ?? batch.status, color: color),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.chipBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${batch.quantity} ${batch.unit}',
                style: TextStyle(color: c.textMuted, fontSize: 11)),
          ),
          if (batch.status == 'CREATED') ...[
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
        ],
      ),
    );
  }
}
