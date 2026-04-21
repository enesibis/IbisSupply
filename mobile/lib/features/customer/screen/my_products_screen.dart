import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/customer_bloc.dart';
import '../../../core/theme/ibis_colors.dart';
import '../../../core/widgets/ibis_app_bar.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerBloc()..add(LoadFavorites()),
      child: const _MyProductsView(),
    );
  }
}

class _MyProductsView extends StatelessWidget {
  const _MyProductsView();

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Scaffold(
      backgroundColor: c.pageBg,
      extendBodyBehindAppBar: true,
      appBar: IbisAppBar(
        title: 'Ürünlerim',
        accentColor: const Color(0xFF42A5F5),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            onPressed: () => context.read<CustomerBloc>().add(LoadFavorites()),
          ),
        ],
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is FavoriteAdded) {
            context.read<CustomerBloc>().add(LoadFavorites());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.productName.isNotEmpty
                  ? '${state.productName} favorilere eklendi'
                  : 'Ürün favorilere eklendi'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is FavoriteRemoved) {
            context.read<CustomerBloc>().add(LoadFavorites());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Favoriden çıkarıldı'),
              backgroundColor: Color(0xFF455A64),
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF42A5F5), strokeWidth: 2));
          }

          if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return _EmptyView();
            }
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
              itemCount: state.favorites.length,
              itemBuilder: (_, i) => _ProductCard(
                item: state.favorites[i],
                onTrace: () => context.push('/product-trace/${state.favorites[i]['batchCode']}'),
                onRemove: () => context.read<CustomerBloc>().add(
                      RemoveFavorite(state.favorites[i]['batchCode']),
                    ),
              ),
            );
          }

          return _EmptyView();
        },
      ),
      floatingActionButton: _AddFavoriteButton(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: c.chipBg,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(Icons.favorite_border_rounded, color: c.textDisabled, size: 56),
          ),
          const SizedBox(height: 20),
          Text('Henüz ürün eklemediniz',
              style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('QR tarayarak ürün ekleyebilirsiniz',
              style: TextStyle(color: c.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push('/qr-public'),
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('QR Tara'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF42A5F5),
              side: const BorderSide(color: Color(0xFF42A5F5)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTrace;
  final VoidCallback onRemove;

  const _ProductCard({required this.item, required this.onTrace, required this.onRemove});

  Color get _statusColor {
    switch (item['status']) {
      case 'DELIVERED': return const Color(0xFF66BB6A);
      case 'IN_TRANSIT': return const Color(0xFFFFB300);
      case 'RECALLED':   return Colors.redAccent;
      default:           return const Color(0xFF42A5F5);
    }
  }

  String get _statusLabel {
    switch (item['status']) {
      case 'DELIVERED': return 'Teslim Edildi';
      case 'IN_TRANSIT': return 'Taşımada';
      case 'RECALLED':   return 'Geri Çağrıldı';
      default:           return 'Oluşturuldu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = IbisColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: c.isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF42A5F5), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['productName'] ?? '',
                        style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item['batchCode'] ?? '',
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTrace,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF1E88E5)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.timeline_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Geçmişi Gör',
                          style: TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item['batchCode'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Batch kodu kopyalandı'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ));
                },
                child: Container(
                  height: 38, width: 38,
                  decoration: BoxDecoration(
                    color: c.chipBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(Icons.copy_rounded, color: c.textMuted, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmRemove(context),
                child: Container(
                  height: 38, width: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.favorite_rounded,
                      color: Colors.red.withValues(alpha: 0.7), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final c = IbisColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.border)),
        title: Text('Favoriden Çıkar',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('${item['productName']} favorilerinizden çıkarılsın mı?',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            child: const Text('Çıkar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddDialog(context),
      backgroundColor: const Color(0xFF1976D2),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Ürün Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  void _showAddDialog(BuildContext context) {
    final c = IbisColors.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.border)),
        title: Text('Batch Kodu ile Ekle',
            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: c.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Örn: BCH-20250409-0001',
            hintStyle: TextStyle(color: c.textDisabled, fontSize: 13),
            filled: true,
            fillColor: c.inputFill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF42A5F5))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İptal', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final code = ctrl.text.trim();
              if (code.isNotEmpty) {
                context.read<CustomerBloc>().add(AddFavorite(code));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ekle',
                style: TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
