import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/farm_bloc.dart';
import '../model/farm_record_model.dart';
import 'farm_detail_screen.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _ink300     = Color(0xFFD4D4D8);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);

const _kFilters = ['Tümü', 'Ekili', 'Hasatlandı'];

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

class _FarmListView extends StatefulWidget {
  const _FarmListView();
  @override
  State<_FarmListView> createState() => _FarmListViewState();
}

class _FarmListViewState extends State<_FarmListView> {
  int _filterIndex = 0;

  List<FarmRecordResponse> _applyFilter(List<FarmRecordResponse> all) {
    switch (_filterIndex) {
      case 1: return all.where((r) => r.plantingDate != null && r.harvestDate == null).toList();
      case 2: return all.where((r) => r.harvestDate != null).toList();
      default: return all;
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kaydı Sil',
            style: AppTheme.sans(fontSize: 16, weight: FontWeight.w600)),
        content: Text('Bu tarımsal kayıt kalıcı olarak silinecek. Emin misiniz?',
            style: AppTheme.sans(fontSize: 14, color: _ink500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTheme.sans(color: _ink400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FarmBloc>().add(DeleteFarmRecord(id));
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
      body: BlocConsumer<FarmBloc, FarmState>(
        listener: (context, state) {
          if (state is FarmRecordDeleted) {
            context.read<FarmBloc>().add(LoadMyFarmRecords());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Kayıt silindi', style: AppTheme.sans()),
              backgroundColor: _ink900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
          if (state is FarmError) {
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
          final allRecords = state is FarmRecordsLoaded
              ? state.records
              : <FarmRecordResponse>[];
          final records = _applyFilter(allRecords);

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
                    'Tarımsal Kayıtlar',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: _ink900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                    color: _ink900,
                    onPressed: () =>
                        context.read<FarmBloc>().add(LoadMyFarmRecords()),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 20),
                    color: _ink900,
                    onPressed: () async {
                      await context.push('/farm-records/create');
                      if (context.mounted) {
                        context.read<FarmBloc>().add(LoadMyFarmRecords());
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _line200),
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
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final active = i == _filterIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: active ? _ink900 : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? _ink900 : _line200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _kFilters[i],
                              style: AppTheme.sans(
                                fontSize: 12,
                                weight: FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF3F3F46),
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
              if (state is FarmLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: _ShimmerCard(),
                      ),
                      childCount: 5,
                    ),
                  ),
                )
              else if (records.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: _line100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.leaf,
                              size: 24, color: _ink400),
                        ),
                        const SizedBox(height: 16),
                        Text('Tarımsal kayıt bulunamadı',
                            style: AppTheme.sans(
                                fontSize: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          _filterIndex == 0
                              ? 'Yeni kayıt eklemek için + ikonuna bas'
                              : 'Farklı bir filtre deneyin',
                          style: AppTheme.sans(fontSize: 13, color: _ink500),
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
                        child: _FarmCard(
                          record: records[i],
                          onDelete: () =>
                              _confirmDelete(ctx, records[i].id),
                        ),
                      ),
                      childCount: records.length,
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

// ── Shimmer card ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: 104,
        decoration: BoxDecoration(
          color: Color.lerp(_line100, Colors.white, _anim.value),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line200),
        ),
      ),
    );
  }
}

// ── Farm card ─────────────────────────────────────────────────────────────────
class _FarmCard extends StatelessWidget {
  final FarmRecordResponse record;
  final VoidCallback onDelete;
  const _FarmCard({required this.record, required this.onDelete});

  static const _irrigationLabels = {
    'DRIP':      'Damla',
    'SPRINKLER': 'Yağmurlama',
    'FLOOD':     'Taşkın',
    'MANUAL':    'Manuel',
  };

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final irrigLabel = _irrigationLabels[record.irrigationType] ??
        record.irrigationType ?? '—';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FarmDetailScreen(record: record))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.productName,
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: _ink900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (record.fieldLocation != null)
                        Row(children: [
                          const Icon(LucideIcons.mapPin,
                              size: 11, color: _ink400),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(record.fieldLocation!,
                                style: AppTheme.sans(
                                    fontSize: 12, color: _ink500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // On-chain badge
                if (record.blockchainTxHash != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.25)),
                    ),
                    child: Text('On-chain',
                        style: AppTheme.sans(
                            fontSize: 10,
                            weight: FontWeight.w600,
                            color: _accent)),
                  ),
              ],
            ),

            // ── Metrics row ──
            const SizedBox(height: 10),
            Row(children: [
              const Icon(LucideIcons.droplets, size: 12, color: _ink400),
              const SizedBox(width: 4),
              Text(
                record.totalIrrigationHours != null
                    ? '$irrigLabel · ${record.totalIrrigationHours!.toStringAsFixed(0)}s'
                    : irrigLabel,
                style: AppTheme.sans(fontSize: 12, color: _ink500),
              ),
              if (record.plantingDate != null) ...[
                const SizedBox(width: 12),
                const Icon(LucideIcons.sprout, size: 12, color: _ink400),
                const SizedBox(width: 4),
                Text(_fmtDate(record.plantingDate!),
                    style: AppTheme.sans(fontSize: 12, color: _ink500)),
              ],
              if (record.harvestDate != null) ...[
                const SizedBox(width: 6),
                const Icon(LucideIcons.arrowRight, size: 11, color: _ink300),
                const SizedBox(width: 6),
                const Icon(LucideIcons.leaf, size: 12, color: _ink400),
                const SizedBox(width: 4),
                Text(_fmtDate(record.harvestDate!),
                    style: AppTheme.sans(fontSize: 12, color: _ink500)),
              ],
            ]),

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: _line100),
            const SizedBox(height: 10),

            // ── Footer ──
            Row(children: [
              Expanded(
                child: Text(
                  record.batchCode,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: _ink400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(LucideIcons.trash2,
                    size: 14, color: _ink300),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
