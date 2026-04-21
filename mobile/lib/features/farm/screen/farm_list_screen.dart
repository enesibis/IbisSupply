import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/farm_bloc.dart';
import '../model/farm_record_model.dart';
import 'farm_detail_screen.dart';
import '../../../core/widgets/ibis_app_bar.dart';
import '../../../core/widgets/ibis_list_tile.dart';
import '../../../core/theme/ibis_colors.dart';

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

  void _confirmDelete(BuildContext context, String id) {
    final c = IbisColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kaydı Sil',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bu tarımsal kayıt kalıcı olarak silinecek. Emin misiniz?',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FarmBloc>().add(DeleteFarmRecord(id));
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
        title: 'Tarımsal Kayıtlar',
        accentColor: const Color(0xFF66BB6A),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<FarmBloc>().add(LoadMyFarmRecords()),
          ),
        ],
      ),
      body: BlocConsumer<FarmBloc, FarmState>(
        listener: (context, state) {
          if (state is FarmRecordDeleted) {
            context.read<FarmBloc>().add(LoadMyFarmRecords());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kayıt silindi'),
              backgroundColor: Color(0xFF455A64),
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is FarmError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is FarmLoading) {
            return Center(
                child: CircularProgressIndicator(
                    color: const Color(0xFF66BB6A), strokeWidth: 2));
          }
          if (state is FarmRecordsLoaded) {
            if (state.records.isEmpty) {
              return const IbisEmptyState(
                icon: Icons.grass_rounded,
                title: 'Henüz tarımsal kayıt yok',
                subtitle: 'Yeni kayıt eklemek için\nsağ alttaki butona bas.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<FarmBloc>().add(LoadMyFarmRecords()),
              color: const Color(0xFF66BB6A),
              backgroundColor: c.surface,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                    16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
                itemCount: state.records.length,
                itemBuilder: (ctx, i) => _FarmCard(
                  record: state.records[i],
                  onDelete: () => _confirmDelete(ctx, state.records[i].id),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: IbisFab(
        onPressed: () async {
          await context.push('/farm-records/create');
          if (context.mounted) context.read<FarmBloc>().add(LoadMyFarmRecords());
        },
        icon: Icons.add_rounded,
        label: 'Yeni Kayıt',
        colors: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final FarmRecordResponse record;
  final VoidCallback onDelete;
  const _FarmCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final irrigationLabel = {
      'DRIP': 'Damla Sulama',
      'SPRINKLER': 'Yağmurlama',
      'FLOOD': 'Taşkın Sulama',
      'MANUAL': 'Manuel',
    }[record.irrigationType] ?? record.irrigationType ?? '-';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FarmDetailScreen(record: record))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: c.isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                    blurRadius: 16, offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
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
                          style: TextStyle(color: c.text,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(record.batchCode,
                          style: TextStyle(color: c.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (record.blockchainTxHash != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.3)),
                    ),
                    child: const Text('On-chain',
                        style: TextStyle(color: Color(0xFF42A5F5),
                            fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.withValues(alpha: 0.7), size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _row(c, Icons.location_on_rounded, 'Tarla', record.fieldLocation ?? '-'),
            const SizedBox(height: 6),
            _row(c, Icons.water_drop_rounded, 'Sulama',
                '$irrigationLabel${record.totalIrrigationHours != null ? ' · ${record.totalIrrigationHours}s' : ''}'),
            if (record.harvestDate != null) ...[
              const SizedBox(height: 6),
              _row(c, Icons.agriculture_rounded, 'Hasat', record.harvestDate!),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: c.border),
              const SizedBox(height: 8),
              Text(record.notes!, style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IbisColors c, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textMuted),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: c.textMuted, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: TextStyle(color: c.text, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
