import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrPublicScreen extends StatefulWidget {
  const QrPublicScreen({super.key});

  @override
  State<QrPublicScreen> createState() => _QrPublicScreenState();
}

class _QrPublicScreenState extends State<QrPublicScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _scanned = true);
    _controller.stop();

    context.pushReplacement('/product-trace/${barcode!.rawValue!}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Kod Okut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              final isPermissionDenied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPermissionDenied
                            ? Icons.no_photography
                            : Icons.error_outline,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isPermissionDenied
                            ? 'Kamera İzni Gerekli'
                            : 'Kamera Açılamadı',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPermissionDenied
                            ? 'QR kod okutmak için kamera iznine ihtiyaç var. Lütfen uygulama ayarlarından kamera iznini açın.'
                            : 'Kamera başlatılırken bir hata oluştu. Lütfen tekrar deneyin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Geri Dön',
                            style: TextStyle(color: Color(0xFF42A5F5))),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF42A5F5), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code, color: Colors.white54, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Ürün üzerindeki QR kodu\nkareye hizalayın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
