import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

const _kFilters = ['Tümü', 'Aktif', 'Yolda', 'Teslim edildi', 'Anomali'];

class _BatchListView extends StatefulWidget {
  const _BatchListView();

  @override
  State<_BatchListView> createState() => _BatchListViewState();
}

class _BatchListViewState extends State<_BatchListView> {
  int _filterIndex = 0;

  List<BatchResponse> _applyFilter(List<BatchResponse> all) {
    switch (_filterIndex) {
      case 1:
        return all.where((b) => b.status == 'CREATED' || b.status == 'IN_WAREHOUSE').toList();
      case 2:
        return all.where((b) => b.status == 'IN_TRANSIT').toList();
      case 3:
        return all.where((b) => b.status == 'SOLD').toList();
      case 4:
        return all.where((b) => b.status == 'RECALLED').toList();
      default:
        return all;
    }
  }

  void _confirmDelete(BuildContext context, BatchResponse batch) {
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batch\'i Sil',
            style: AppTheme.sans(fontSize: 16, weight: FontWeight.w600)),
        content: Text(
          '${batch.productName} batch\'i kalıcı olarak silinecek. Emin misiniz?',
          style: AppTheme.sans(fontSize: 14, color: const Color(0xFF52525B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTheme.sans(color: const Color(0xFF71717A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BatchBloc>().add(DeleteBatch(batch.id));
            },
            child: Text('Sil', style: AppTheme.sans(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<BatchBloc, BatchState>(
        listener: (context, state) {
          if (state is BatchDeleted) {
            context.read<BatchBloc>().add(LoadBatches());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Batch silindi', style: AppTheme.sans()),
              backgroundColor: AppTheme.ink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
          if (state is BatchError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: AppTheme.sans()),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
        builder: (context, state) {
          final batches = state is BatchListLoaded
              ? _applyFilter(state.batches)
              : <BatchResponse>[];

          return CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  expandedTitleScale: 1.0,
                  title: Text(
                    "Batch'ler",
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.ink,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.search, size: 20),
                    color: AppTheme.ink,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 20),
                    color: AppTheme.ink,
                    onPressed: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const BatchCreateScreen()),
                      );
                      if (created == true && context.mounted) {
                        context.read<BatchBloc>().add(LoadBatches());
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: const Color(0xFFE4E4E7)),
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    itemCount: _kFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final active = i == _filterIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? AppTheme.ink : const Color(0xFFE4E4E7),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _kFilters[i],
                              style: AppTheme.sans(
                                fontSize: 12,
                                weight: FontWeight.w500,
                                color: active ? Colors.white : const Color(0xFF3F3F46),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────
              if (state is BatchLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3F3FE8),
                    ),
                  ),
                )
              else if (state is BatchError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            size: 32, color: Color(0xFFB91C1C)),
                        const SizedBox(height: 12),
                        Text(state.message, style: AppTheme.sans(fontSize: 14)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.read<BatchBloc>().add(LoadBatches()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.ink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Tekrar dene',
                                style: AppTheme.sans(
                                    color: Colors.white,
                                    weight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (batches.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.package,
                              size: 24, color: Color(0xFFA1A1AA)),
                        ),
                        const SizedBox(height: 16),
                        Text('Batch bulunamadı',
                            style: AppTheme.sans(
                                fontSize: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          _filterIndex == 0
                              ? 'Yeni batch oluşturmak için + ikonuna bas'
                              : 'Farklı bir filtre deneyin',
                          style: AppTheme.sans(
                              fontSize: 13, color: const Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BatchCard(
                          batch: batches[i],
                          onDelete: () => _confirmDelete(ctx, batches[i]),
                        ),
                      ),
                      childCount: batches.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Batch card ────────────────────────────────────────────────────────────────
class _BatchCard extends StatelessWidget {
  final BatchResponse batch;
  final VoidCallback onDelete;
  const _BatchCard({required this.batch, required this.onDelete});

  String get _tagLabel {
    switch (batch.status) {
      case 'SOLD':
        return 'Teslim';
      case 'RECALLED':
        return 'Anomali';
      case 'IN_TRANSIT':
        return 'Yolda';
      default:
        return 'Aktif';
    }
  }

  Color get _tagFg {
    switch (batch.status) {
      case 'SOLD':
        return const Color(0xFF0F7A4B);
      case 'RECALLED':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF3F3FE8);
    }
  }

  Color get _tagBg {
    switch (batch.status) {
      case 'SOLD':
        return const Color(0xFFE6F4EF);
      case 'RECALLED':
        return const Color(0xFFFBF1E1);
      default:
        return const Color(0xFFEEEEFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailScreen(batch: batch)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName,
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${batch.quantity.toStringAsFixed(0)} ${batch.unit}',
                            style: AppTheme.sans(
                                fontSize: 12, color: const Color(0xFF71717A)),
                          ),
                          if (batch.originLocation != null) ...[
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.mapPin,
                                size: 11, color: Color(0xFF71717A)),
                            const SizedBox(width: 2),
                            Text(
                              batch.originLocation!,
                              style: AppTheme.sans(
                                  fontSize: 12, color: const Color(0xFF71717A)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Status tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tagBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _tagLabel,
                    style: AppTheme.sans(
                      fontSize: 11,
                      weight: FontWeight.w600,
                      color: _tagFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
            const SizedBox(height: 10),
            // Footer row
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.batchCode,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFFA1A1AA),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (batch.status == 'CREATED')
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(LucideIcons.trash2,
                        size: 14, color: Color(0xFFD4D4D8)),
                  )
                else
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: Color(0xFFD4D4D8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
