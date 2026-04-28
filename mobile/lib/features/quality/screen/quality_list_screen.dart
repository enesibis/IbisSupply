import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/quality_bloc.dart';
import '../model/quality_check_model.dart';
import '../../../core/theme/app_theme.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _accent  = Color(0xFF3F3FE8);
const _ink900  = Color(0xFF0A0A0B);
const _ink500  = Color(0xFF71717A);
const _ink400  = Color(0xFFA1A1AA);
const _ink300  = Color(0xFFD4D4D8);
const _line200 = Color(0xFFE4E4E7);
const _line100 = Color(0xFFF4F4F5);

const _kFilters = ['Tümü', 'Geçti', 'İnceleme', 'Başarısız'];

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

class _QualityListView extends StatefulWidget {
  const _QualityListView();
  @override
  State<_QualityListView> createState() => _QualityListViewState();
}

class _QualityListViewState extends State<_QualityListView> {
  int _filterIndex = 0;

  List<QualityCheckResponse> _applyFilter(List<QualityCheckResponse> all) {
    switch (_filterIndex) {
      case 1: return all.where((c) => c.result == 'PASSED').toList();
      case 2: return all.where((c) => c.result == 'NEEDS_REVIEW').toList();
      case 3: return all.where((c) => c.result == 'FAILED').toList();
      default: return all;
    }
  }

  void _confirmDelete(BuildContext context, QualityCheckResponse check) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Kaydı Sil',
            style: AppTheme.sans(fontSize: 16, weight: FontWeight.w600)),
        content: Text(
          '${check.productName} kalite kontrol kaydı silinecek. Emin misiniz?',
          style: AppTheme.sans(fontSize: 14, color: _ink500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: AppTheme.sans(color: _ink400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<QualityBloc>().add(DeleteCheck(check.id));
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
      body: BlocConsumer<QualityBloc, QualityState>(
        listener: (context, state) {
          if (state is CheckDeleted) {
            context.read<QualityBloc>().add(LoadMyChecks());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Kayıt silindi', style: AppTheme.sans()),
              backgroundColor: _ink900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
          if (state is QualityError) {
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
          final allChecks = state is ChecksLoaded ? state.checks : <QualityCheckResponse>[];
          final checks    = _applyFilter(allChecks);

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
                    'Kalite Kontrol',
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
                    onPressed: () => context.read<QualityBloc>().add(LoadMyChecks()),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, size: 20),
                    color: _ink900,
                    onPressed: () => context.push('/quality-checks/create'),
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
              if (state is QualityLoading)
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
              else if (state is QualityError)
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
                          onTap: () => context.read<QualityBloc>().add(LoadMyChecks()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                                color: _ink900,
                                borderRadius: BorderRadius.circular(10)),
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
              else if (checks.isEmpty)
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
                          child: const Icon(LucideIcons.shieldCheck,
                              size: 24, color: _ink400),
                        ),
                        const SizedBox(height: 16),
                        Text('Kontrol kaydı bulunamadı',
                            style: AppTheme.sans(
                                fontSize: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          _filterIndex == 0
                              ? 'Yeni kontrol eklemek için + ikonuna bas'
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
                        child: _CheckCard(
                          check: checks[i],
                          onDelete: () => _confirmDelete(ctx, checks[i]),
                        ),
                      ),
                      childCount: checks.length,
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
        height: 98,
        decoration: BoxDecoration(
          color: Color.lerp(_line100, Colors.white, _anim.value),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line200),
        ),
      ),
    );
  }
}

// ── Check card ────────────────────────────────────────────────────────────────
class _CheckCard extends StatelessWidget {
  final QualityCheckResponse check;
  final VoidCallback onDelete;
  const _CheckCard({required this.check, required this.onDelete});

  String get _tagLabel {
    switch (check.result) {
      case 'PASSED':      return 'Geçti';
      case 'FAILED':      return 'Başarısız';
      case 'NEEDS_REVIEW':return 'İnceleme';
      default:            return check.result;
    }
  }

  Color get _tagFg {
    switch (check.result) {
      case 'PASSED':      return const Color(0xFF0F7A4B);
      case 'FAILED':      return const Color(0xFFB91C1C);
      case 'NEEDS_REVIEW':return const Color(0xFFB45309);
      default:            return _accent;
    }
  }

  Color get _tagBg {
    switch (check.result) {
      case 'PASSED':      return const Color(0xFFE6F4EE);
      case 'FAILED':      return const Color(0xFFFEECEC);
      case 'NEEDS_REVIEW':return const Color(0xFFFBF1E1);
      default:            return const Color(0xFFEEEEFE);
    }
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        check.productName,
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: _ink900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(LucideIcons.user, size: 11, color: _ink400),
                        const SizedBox(width: 4),
                        Text(check.inspectorName,
                            style: AppTheme.sans(fontSize: 12, color: _ink500)),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.calendar, size: 11, color: _ink400),
                        const SizedBox(width: 4),
                        Text(_fmtDate(check.checkedAt),
                            style: AppTheme.sans(fontSize: 12, color: _ink500)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tagBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_tagLabel,
                      style: AppTheme.sans(
                          fontSize: 11, weight: FontWeight.w600, color: _tagFg)),
                ),
              ],
            ),

            // ── Metrics row (if available) ──
            if (check.temperature != null || check.humidity != null ||
                check.contaminationDetected == true) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (check.temperature != null) ...[
                  const Icon(LucideIcons.thermometer, size: 12, color: _ink400),
                  const SizedBox(width: 3),
                  Text('${check.temperature!.toStringAsFixed(1)}°C',
                      style: AppTheme.sans(fontSize: 11, color: _ink500)),
                  const SizedBox(width: 10),
                ],
                if (check.humidity != null) ...[
                  const Icon(LucideIcons.droplets, size: 12, color: _ink400),
                  const SizedBox(width: 3),
                  Text('%${check.humidity!.toStringAsFixed(0)}',
                      style: AppTheme.sans(fontSize: 11, color: _ink500)),
                  const SizedBox(width: 10),
                ],
                if (check.contaminationDetected == true) ...[
                  const Icon(LucideIcons.alertTriangle,
                      size: 12, color: Color(0xFFB91C1C)),
                  const SizedBox(width: 3),
                  Text('Kirlilik',
                      style: AppTheme.sans(
                          fontSize: 11,
                          weight: FontWeight.w600,
                          color: Color(0xFFB91C1C))),
                ],
              ]),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: _line100),
            const SizedBox(height: 10),

            // ── Footer ──
            Row(children: [
              Expanded(
                child: Text(
                  check.batchCode,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: _ink400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(LucideIcons.trash2, size: 14, color: _ink300),
              ),
            ]),
          ],
        ),
      );
  }
}
