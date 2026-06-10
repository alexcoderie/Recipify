import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'product_details_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();
    _navigateToProduct(barcode);
  }

  void _navigateToProduct(String barcode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(barcode: barcode),
      ),
    ).then((_) {
      setState(() => _isProcessing = false);
      _controller.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _torchOn
                          ? LucideIcons.flashlight
                          : LucideIcons.flashlightOff,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onBarcodeDetected,
                  ),

                  _ScannerOverlay(),

                  _ScannerFrame(isScanning: _isProcessing),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  const Text(
                    'Position barcode within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The barcode will be scanned automatically',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _navigateToProduct('737628064502'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isProcessing ? 'Scanning...' : 'Manual Scan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 280.0;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );

    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              frameRect, const Radius.circular(16))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerFrame extends StatelessWidget {
  final bool isScanning;
  const _ScannerFrame({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          if (isScanning)
            Center(
              child: AnimatedOpacity(
                opacity: isScanning ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  height: 2,
                  color: Colors.green,
                ),
              ),
            ),

          Positioned(
            top: 0, left: 0,
            child: _Corner(
              borders: const [BorderSide.none, BorderSide.none,
                BorderSide.none, BorderSide.none],
              topLeft: true,
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: _Corner(topRight: true),
          ),
          Positioned(
            bottom: 0, left: 0,
            child: _Corner(bottomLeft: true),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: _Corner(bottomRight: true),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final List<BorderSide>? borders;

  const _Corner({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    this.borders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: (topLeft || topRight)
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
          bottom: (bottomLeft || bottomRight)
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
          left: (topLeft || bottomLeft)
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
          right: (topRight || bottomRight)
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft:
          topLeft ? const Radius.circular(16) : Radius.zero,
          topRight:
          topRight ? const Radius.circular(16) : Radius.zero,
          bottomLeft:
          bottomLeft ? const Radius.circular(16) : Radius.zero,
          bottomRight:
          bottomRight ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}