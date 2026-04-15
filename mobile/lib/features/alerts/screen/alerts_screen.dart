import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alert_bloc.dart';
import '../model/alert_model.dart';

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
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Uyarılar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AlertBloc>().add(LoadAlerts()),
          ),
        ],
      ),
      body: BlocConsumer<AlertBloc, AlertState>(
        listener: (context, state) {
          if (state is AlertError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is AlertLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is AlertsLoaded) {
            if (state.alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_rounded,
                        size: 56, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('Aktif uyarı yok',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 15)),
                  ],
                ),
              );
            }

            final unresolved = state.alerts.where((a) => !a.resolved).toList();
            final resolved = state.alerts.where((a) => a.resolved).toList();

            return RefreshIndicator(
              onRefresh: () async => context.read<AlertBloc>().add(LoadAlerts()),
              color: const Color(0xFF1976D2),
              backgroundColor: const Color(0xFF0B1A33),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (unresolved.isNotEmpty) ...[
                    _sectionLabel('Aktif (${unresolved.length})'),
                    const SizedBox(height: 8),
                    ...unresolved.map((a) => _AlertCard(alert: a)),
                  ],
                  if (resolved.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('Çözüldü (${resolved.length})'),
                    const SizedBox(height: 8),
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

  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colors = _severityColors(alert.severity);
    final typeLabel = _typeLabel(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.resolved
            ? const Color(0xFF0B1A33).withValues(alpha: 0.5)
            : const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: alert.resolved
                ? Colors.white.withValues(alpha: 0.05)
                : colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(colors.icon, color: colors.fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(alert.severity,
                          style: TextStyle(
                              color: colors.fg,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(typeLabel,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(alert.message,
                    style: TextStyle(
                        color: alert.resolved
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.white,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (alert.batchCode != null)
                      Text(alert.batchCode!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11)),
                    if (alert.shipmentCode != null) ...[
                      if (alert.batchCode != null)
                        Text(' · ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 11)),
                      Text(alert.shipmentCode!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!alert.resolved)
            GestureDetector(
              onTap: () => context.read<AlertBloc>().add(ResolveAlert(alert.id)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
                ),
                child: const Text('Çözüldü',
                    style: TextStyle(
                        color: Color(0xFF66BB6A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            )
          else
            Icon(Icons.check_circle_rounded,
                color: const Color(0xFF66BB6A).withValues(alpha: 0.4), size: 18),
        ],
      ),
    );
  }

  _SeverityStyle _severityColors(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return _SeverityStyle(
          bg: const Color(0xFFB71C1C).withValues(alpha: 0.15),
          fg: const Color(0xFFEF9A9A),
          border: const Color(0xFFEF9A9A).withValues(alpha: 0.3),
          icon: Icons.warning_rounded,
        );
      case 'HIGH':
        return _SeverityStyle(
          bg: const Color(0xFFE65100).withValues(alpha: 0.15),
          fg: const Color(0xFFFFB74D),
          border: const Color(0xFFFFB74D).withValues(alpha: 0.3),
          icon: Icons.error_rounded,
        );
      case 'MEDIUM':
        return _SeverityStyle(
          bg: const Color(0xFFF9A825).withValues(alpha: 0.12),
          fg: const Color(0xFFFFE082),
          border: const Color(0xFFFFE082).withValues(alpha: 0.25),
          icon: Icons.info_rounded,
        );
      default: // LOW
        return _SeverityStyle(
          bg: const Color(0xFF1565C0).withValues(alpha: 0.12),
          fg: const Color(0xFF42A5F5),
          border: const Color(0xFF42A5F5).withValues(alpha: 0.2),
          icon: Icons.notifications_rounded,
        );
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'TEMPERATURE_ANOMALY': return 'Sıcaklık Anomalisi';
      case 'QUALITY_FAIL': return 'Kalite Kontrolü';
      case 'AI_RISK': return 'AI Risk';
      case 'DELAY': return 'Gecikme';
      default: return type;
    }
  }
}

class _SeverityStyle {
  final Color bg, fg, border;
  final IconData icon;
  const _SeverityStyle(
      {required this.bg,
      required this.fg,
      required this.border,
      required this.icon});
}
