import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/batch_bloc.dart';
import '../model/batch_model.dart';
import '../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Batch Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BatchBloc>().add(LoadBatches()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const BatchCreateScreen()),
          );
          if (created == true && context.mounted) {
            context.read<BatchBloc>().add(LoadBatches());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Batch'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<BatchBloc, BatchState>(
        builder: (context, state) {
          if (state is BatchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BatchError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.message, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BatchBloc>().add(LoadBatches()),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          if (state is BatchListLoaded) {
            if (state.batches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Henüz batch yok', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Yeni batch oluşturmak için + butonuna bas',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.batches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _BatchCard(batch: state.batches[i]),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final BatchResponse batch;
  const _BatchCard({required this.batch});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(batch.status);
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BatchDetailScreen(batch: batch)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(batch.batchCode,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(status: batch.status, color: statusColor),
                        const SizedBox(width: 8),
                        Text('${batch.quantity} ${batch.unit}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CREATED': return const Color(0xFF1565C0);
      case 'IN_TRANSIT': return const Color(0xFF6A1B9A);
      case 'IN_WAREHOUSE': return const Color(0xFF2E7D32);
      case 'SOLD': return const Color(0xFF00695C);
      case 'RECALLED': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  static const _labels = {
    'CREATED': 'Oluşturuldu',
    'IN_TRANSIT': 'Taşımada',
    'IN_WAREHOUSE': 'Depoda',
    'SOLD': 'Satıldı',
    'RECALLED': 'Geri Çağrıldı',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
