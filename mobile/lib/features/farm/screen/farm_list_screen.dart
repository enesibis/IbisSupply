import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/farm_bloc.dart';
import '../model/farm_record_model.dart';
import 'farm_detail_screen.dart';

class FarmListScreen extends StatelessWidget {
  const FarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FarmBloc()..add(LoadMyFarmRecords()),
      child: const _FarmListView(),
    );
  }
}

class _FarmListView extends StatelessWidget {
  const _FarmListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Tarımsal Kayıtlar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/farm-records/create'),
          ),
        ],
      ),
      body: BlocConsumer<FarmBloc, FarmState>(
        listener: (context, state) {
          if (state is FarmError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is FarmLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is FarmRecordsLoaded) {
            if (state.records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grass_rounded,
                        size: 56, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('Henüz tarımsal kayıt yok',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 15)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<FarmBloc>().add(LoadMyFarmRecords()),
              color: const Color(0xFF1976D2),
              backgroundColor: const Color(0xFF0B1A33),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.records.length,
                itemBuilder: (ctx, i) => _FarmCard(record: state.records[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/farm-records/create');
          if (context.mounted) {
            context.read<FarmBloc>().add(LoadMyFarmRecords());
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final FarmRecordResponse record;
  const _FarmCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final irrigationLabel = {
      'DRIP': 'Damla Sulama',
      'SPRINKLER': 'Yağmurlama',
      'FLOOD': 'Taşkın Sulama',
      'MANUAL': 'Manuel',
    }[record.irrigationType] ?? record.irrigationType ?? '-';

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.grass_rounded,
                    color: Color(0xFF66BB6A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.productName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(record.batchCode,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12)),
                  ],
                ),
              ),
              if (record.blockchainTxHash != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.3)),
                  ),
                  child: const Text('On-chain',
                      style: TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Detay satırları
          _row(Icons.location_on_rounded, 'Tarla',
              record.fieldLocation ?? '-'),
          const SizedBox(height: 6),
          _row(Icons.water_drop_rounded, 'Sulama',
              '$irrigationLabel${record.totalIrrigationHours != null ? ' · ${record.totalIrrigationHours}s' : ''}'),
          if (record.harvestDate != null) ...[
            const SizedBox(height: 6),
            _row(Icons.agriculture_rounded, 'Hasat', record.harvestDate!),
          ],
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            Text(record.notes!,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12)),
          ],
        ],
      ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FarmDetailScreen(record: record),
    ));
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.35)),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
