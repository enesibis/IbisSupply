import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/batch_bloc.dart';
import '../model/batch_model.dart';
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
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        title: const Text(
          'Batch Yönetimi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.6)),
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
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<BatchBloc, BatchState>(
        builder: (context, state) {
          if (state is BatchLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is BatchError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(state.message,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () =>
                          context.read<BatchBloc>().add(LoadBatches()),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF1976D2).withValues(alpha: 0.2),
                        foregroundColor: const Color(0xFF42A5F5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is BatchListLoaded) {
            if (state.batches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Text('Henüz batch yok',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Yeni batch oluşturmak için + butonuna bas',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 13)),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'CREATED':
        return const Color(0xFF42A5F5);
      case 'IN_TRANSIT':
        return const Color(0xFFCE93D8);
      case 'IN_WAREHOUSE':
        return const Color(0xFF66BB6A);
      case 'SOLD':
        return const Color(0xFF4DB6AC);
      case 'RECALLED':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  static const _statusLabels = {
    'CREATED': 'Oluşturuldu',
    'IN_TRANSIT': 'Taşımada',
    'IN_WAREHOUSE': 'Depoda',
    'SOLD': 'Satıldı',
    'RECALLED': 'Geri Çağrıldı',
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(batch.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailScreen(batch: batch)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        batch.batchCode,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              _statusLabels[batch.status] ?? batch.status,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${batch.quantity} ${batch.unit}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
