import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alert_bloc.dart';
import '../model/alert_model.dart';
import '../../../core/widgets/ibis_app_bar.dart';
import '../../../core/widgets/ibis_list_tile.dart';
import '../../../core/theme/ibis_colors.dart';

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
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Uyarılar',
        accentColor: const Color(0xFFEF9A9A),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<AlertBloc>().add(LoadAlerts()),
          ),
        ],
      ),
      body: BlocConsumer<AlertBloc, AlertState>(
        listener: (context, state) {
          if (state is AlertError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFB71C1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
        builder: (context, state) {
          if (state is AlertLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFEF9A9A), strokeWidth: 2));
          }
          if (state is AlertsLoaded) {
            if (state.alerts.isEmpty) {
              return const IbisEmptyState(
                icon: Icons.notifications_off_rounded,
                title: 'Aktif uyarı yok',
                subtitle: 'Sistem normal çalışıyor.\nBir anomali oluştuğunda burada görünür.',
              );
            }
            final unresolved = state.alerts.where((a) => !a.resolved).toList();
            final resolved = state.alerts.where((a) => a.resolved).toList();

            return RefreshIndicator(
              onRefresh: () async => context.read<AlertBloc>().add(LoadAlerts()),
              color: const Color(0xFF1976D2),
              backgroundColor: c.surface,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 32),
                children: [
                  if (unresolved.isNotEmpty) ...[
                    _SectionHeader(text: 'Aktif', count: unresolved.length),
                    const SizedBox(height: 10),
                    ...unresolved.map((a) => _AlertCard(alert: a)),
                  ],
                  if (resolved.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(text: 'Çözüldü', count: resolved.length),
                    const SizedBox(height: 10),
                    ...resolved.map((a) => _AlertCard(alert: a)),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final int count;
  const _SectionHeader({required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Row(
      children: [
        Text(text,
            style: TextStyle(
              color: c.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: c.chipBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  _SeverityStyle get _style {
    switch (alert.severity) {
      case 'CRITICAL':
        return const _SeverityStyle(color: Color(0xFFEF9A9A), icon: Icons.warning_rounded);
      case 'HIGH':
        return const _SeverityStyle(color: Color(0xFFFFB74D), icon: Icons.error_rounded);
      case 'MEDIUM':
        return const _SeverityStyle(color: Color(0xFFFFE082), icon: Icons.info_rounded);
      default:
        return const _SeverityStyle(color: Color(0xFF42A5F5), icon: Icons.notifications_rounded);
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case 'TEMPERATURE_ANOMALY': return 'Sıcaklık Anomalisi';
      case 'QUALITY_FAIL': return 'Kalite Kontrolü';
      case 'AI_RISK': return 'AI Risk';
      case 'DELAY': return 'Gecikme';
      default: return alert.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    final style = _style;
    final dimmed = alert.resolved;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IbisListTile(
        accentColor: dimmed ? c.textDisabled : style.color,
        icon: Icon(style.icon,
            color: dimmed ? c.textDisabled : style.color, size: 22),
        title: Text(
          alert.message,
          style: TextStyle(
            color: dimmed ? c.textMuted : c.text,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _typeLabel,
          style: TextStyle(
              color: dimmed ? c.textDisabled : style.color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
        badge: Row(
          children: [
            if (alert.batchCode != null) _CodeChip(text: alert.batchCode!),
            if (alert.shipmentCode != null) ...[
              if (alert.batchCode != null) const SizedBox(width: 6),
              _CodeChip(text: alert.shipmentCode!),
            ],
          ],
        ),
        trailing: dimmed
            ? Icon(Icons.check_circle_rounded,
                color: const Color(0xFF66BB6A).withValues(alpha: 0.5), size: 18)
            : GestureDetector(
                onTap: () => context.read<AlertBloc>().add(ResolveAlert(alert.id)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF1B5E20), Color(0xFF2E7D32),
                    ]),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: const Color(0xFF66BB6A).withValues(alpha: 0.4)),
                  ),
                  child: const Text('Çözüldü',
                      style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String text;
  const _CodeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.border),
      ),
      child: Text(text,
          style: TextStyle(
              color: c.textMuted, fontSize: 10, fontFamily: 'monospace')),
    );
  }
}

class _SeverityStyle {
  final Color color;
  final IconData icon;
  const _SeverityStyle({required this.color, required this.icon});
}
