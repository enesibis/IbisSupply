import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/quality_bloc.dart';
import '../model/quality_check_model.dart';

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

class _QualityListView extends StatelessWidget {
  const _QualityListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A33),
        foregroundColor: Colors.white,
        title: const Text('Kalite Kontrol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/quality-checks/create'),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<QualityBloc, QualityState>(
        builder: (context, state) {
          if (state is QualityLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          if (state is QualityError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<QualityBloc>().add(LoadMyChecks()),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          if (state is ChecksLoaded) {
            if (state.checks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, color: Colors.white.withValues(alpha: 0.3), size: 64),
                    const SizedBox(height: 16),
                    Text('Henüz kontrol kaydı yok',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.checks.length,
              itemBuilder: (_, i) => _CheckCard(check: state.checks[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final QualityCheckResponse check;
  const _CheckCard({required this.check});

  Color get _resultColor {
    switch (check.result) {
      case 'PASSED': return const Color(0xFF66BB6A);
      case 'FAILED': return Colors.redAccent;
      case 'NEEDS_REVIEW': return const Color(0xFFFFB300);
      default: return Colors.grey;
    }
  }

  String get _resultLabel {
    switch (check.result) {
      case 'PASSED': return 'Geçti';
      case 'FAILED': return 'Başarısız';
      case 'NEEDS_REVIEW': return 'İnceleme Gerekli';
      default: return check.result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _resultColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              check.result == 'PASSED' ? Icons.check_circle_rounded
                  : check.result == 'FAILED' ? Icons.cancel_rounded
                  : Icons.pending_rounded,
              color: _resultColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.productName,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(check.batchCode,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                if (check.notes != null && check.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(check.notes!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _resultColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _resultColor.withValues(alpha: 0.3)),
            ),
            child: Text(_resultLabel,
                style: TextStyle(color: _resultColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
