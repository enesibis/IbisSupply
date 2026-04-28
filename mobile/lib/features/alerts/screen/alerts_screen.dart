import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/alert_bloc.dart';
import '../model/alert_model.dart';
import '../../../core/theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlertBloc()..add(LoadAlerts()),
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AlertBloc, AlertState>(
        listener: (context, state) {
          if (state is AlertError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: AppTheme.sans()),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
        builder: (context, state) {
          final alerts =
              state is AlertsLoaded ? state.alerts : <AlertModel>[];

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
                    'Uyarılar',
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
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    color: AppTheme.ink,
                    onPressed: () =>
                        context.read<AlertBloc>().add(LoadAlerts()),
                  ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child:
                      Container(height: 1, color: const Color(0xFFE4E4E7)),
                ),
              ),

              // ── States ───────────────────────────────────────────────
              if (state is AlertLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF3F3FE8)),
                  ),
                )
              else if (state is AlertError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            size: 32, color: Color(0xFFB91C1C)),
                        const SizedBox(height: 12),
                        Text(state.message,
                            style: AppTheme.sans(fontSize: 14)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () =>
                              context.read<AlertBloc>().add(LoadAlerts()),
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
              else if (alerts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.bellOff,
                              size: 24, color: Color(0xFFA1A1AA)),
                        ),
                        const SizedBox(height: 16),
                        Text('Aktif uyarı yok',
                            style: AppTheme.sans(
                                fontSize: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Sistem normal çalışıyor',
                            style: AppTheme.sans(
                                fontSize: 13,
                                color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                )
              else ...[
                // Summary tags
                SliverToBoxAdapter(child: _SummaryRow(alerts: alerts)),
                // List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(alert: alerts[i]),
                      ),
                      childCount: alerts.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<AlertModel> alerts;
  const _SummaryRow({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final critical = alerts
        .where((a) =>
            !a.resolved &&
            (a.severity == 'CRITICAL' || a.severity == 'HIGH'))
        .length;
    final medium = alerts
        .where((a) => !a.resolved && a.severity == 'MEDIUM')
        .length;
    final resolvedCount = alerts.where((a) => a.resolved).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (critical > 0)
            _SummaryTag(
                label: '$critical kritik',
                fg: const Color(0xFFB91C1C),
                bg: const Color(0xFFFBE8E8)),
          if (medium > 0)
            _SummaryTag(
                label: '$medium orta',
                fg: const Color(0xFFB45309),
                bg: const Color(0xFFFBF1E1)),
          if (resolvedCount > 0)
            _SummaryTag(
                label: '$resolvedCount çözüldü',
                fg: const Color(0xFF0F7A4B),
                bg: const Color(0xFFE6F4EF)),
          if (critical == 0 && medium == 0 && resolvedCount == 0)
            _SummaryTag(
                label: 'Tümü bilgi',
                fg: const Color(0xFF3F3F46),
                bg: const Color(0xFFF4F4F5)),
        ],
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const _SummaryTag(
      {required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTheme.sans(
              fontSize: 12, weight: FontWeight.w600, color: fg)),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  IconData get _icon {
    switch (alert.type) {
      case 'TEMPERATURE_ANOMALY': return LucideIcons.thermometer;
      case 'QUALITY_FAIL':        return LucideIcons.shieldAlert;
      case 'AI_RISK':             return LucideIcons.sparkles;
      case 'DELAY':               return LucideIcons.clock;
      default:                    return LucideIcons.bell;
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case 'TEMPERATURE_ANOMALY': return 'Sıcaklık anomalisi';
      case 'QUALITY_FAIL':        return 'Kalite testi';
      case 'AI_RISK':             return 'AI risk';
      case 'DELAY':               return 'Gecikme tahmini';
      default:
        return alert.type.toLowerCase().replaceAll('_', ' ');
    }
  }

  String get _riskLabel {
    switch (alert.severity) {
      case 'CRITICAL': return 'KRİTİK';
      case 'HIGH':     return 'YÜKSEK';
      case 'MEDIUM':   return 'ORTA';
      case 'LOW':      return 'DÜŞÜK';
      default:         return alert.severity;
    }
  }

  Color get _iconFg {
    if (alert.resolved) return const Color(0xFFA1A1AA);
    switch (alert.severity) {
      case 'CRITICAL':
      case 'HIGH':   return const Color(0xFFB91C1C);
      case 'MEDIUM': return const Color(0xFFB45309);
      default:       return const Color(0xFF3F3F46);
    }
  }

  Color get _iconBg {
    if (alert.resolved) return const Color(0xFFF4F4F5);
    switch (alert.severity) {
      case 'CRITICAL':
      case 'HIGH':   return const Color(0xFFFBE8E8);
      case 'MEDIUM': return const Color(0xFFFBF1E1);
      default:       return const Color(0xFFF4F4F5);
    }
  }

  Color get _riskFg {
    switch (alert.severity) {
      case 'CRITICAL':
      case 'HIGH':   return const Color(0xFFB91C1C);
      case 'MEDIUM': return const Color(0xFFB45309);
      default:       return const Color(0xFF3F3F46);
    }
  }

  Color get _riskBg {
    switch (alert.severity) {
      case 'CRITICAL':
      case 'HIGH':   return const Color(0xFFFBE8E8);
      case 'MEDIUM': return const Color(0xFFFBF1E1);
      default:       return const Color(0xFFF4F4F5);
    }
  }

  String _relativeTime(String createdAt) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(createdAt));
      if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
      if (diff.inHours < 24) return '${diff.inHours}s';
      if (diff.inDays == 1) return 'Dün';
      return '${diff.inDays}g';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 17, color: _iconFg),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        alert.message,
                        style: AppTheme.sans(
                          fontSize: 13,
                          weight: FontWeight.w600,
                          color: alert.resolved
                              ? const Color(0xFFA1A1AA)
                              : AppTheme.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(alert.createdAt),
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: const Color(0xFFA1A1AA)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_typeLabel,
                    style: AppTheme.sans(
                        fontSize: 12, color: const Color(0xFF71717A))),

                // Code chips
                if (alert.batchCode != null || alert.shipmentCode != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (alert.batchCode != null)
                        _CodeChip(text: alert.batchCode!),
                      if (alert.shipmentCode != null)
                        _CodeChip(text: alert.shipmentCode!),
                    ],
                  ),
                ],

                // Risk tag + action
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!alert.resolved && alert.severity != 'LOW')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _riskBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Risk · $_riskLabel',
                          style: AppTheme.sans(
                              fontSize: 11,
                              weight: FontWeight.w600,
                              color: _riskFg),
                        ),
                      ),
                    const Spacer(),
                    if (alert.resolved)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.checkCircle2,
                              size: 14, color: Color(0xFF0F7A4B)),
                          const SizedBox(width: 4),
                          Text('Çözüldü',
                              style: AppTheme.sans(
                                  fontSize: 11,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF0F7A4B))),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => context
                            .read<AlertBloc>()
                            .add(ResolveAlert(alert.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE4E4E7)),
                          ),
                          child: Text('Çözüldü işaretle',
                              style: AppTheme.sans(
                                  fontSize: 11,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF52525B))),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Code chip ─────────────────────────────────────────────────────────────────
class _CodeChip extends StatelessWidget {
  final String text;
  const _CodeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Text(text,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: const Color(0xFF71717A))),
    );
  }
}
