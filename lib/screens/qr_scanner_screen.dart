import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../themes/theme.dart';
import '../widgets/reusable_components.dart';

/// QR Scanner Screen with custom overlay and manual code entry
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        // Handle scanned QR code
        debugPrint('QR Code detected: ${barcode.rawValue}');
        // You can navigate or show a dialog here
      }
    }
  }

  void _submitManualCode() {
    if (_manualCodeController.text.isNotEmpty) {
      // Handle manual code entry
      debugPrint('Manual code entered: ${_manualCodeController.text}');
      // You can navigate or show a dialog here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Mobile Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQrDetected,
          ),
          
          // Dark overlay with transparent cutout
          CustomPaint(
            painter: _QrScannerOverlayPainter(),
            child: Container(),
          ),
          
          // Orange corner borders
          Center(
            child: Container(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBorder(
                      isTopLeft: true,
                    ),
                  ),
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerBorder(
                      isTopRight: true,
                    ),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerBorder(
                      isBottomLeft: true,
                    ),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerBorder(
                      isBottomRight: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Manual code entry section at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Code Manually',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualCodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter bike code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryOrange,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Submit Code',
                      onPressed: _submitManualCode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dark overlay with transparent square cutout
class _QrScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final cutoutSize = 250.0;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutSize,
      height: cutoutSize,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Orange corner border widget
class _CornerBorder extends StatelessWidget {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  const _CornerBorder({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: (isTopLeft || isTopRight)
              ? BorderSide(color: AppTheme.primaryOrange, width: 4)
              : BorderSide.none,
          bottom: (isBottomLeft || isBottomRight)
              ? BorderSide(color: AppTheme.primaryOrange, width: 4)
              : BorderSide.none,
          left: (isTopLeft || isBottomLeft)
              ? BorderSide(color: AppTheme.primaryOrange, width: 4)
              : BorderSide.none,
          right: (isTopRight || isBottomRight)
              ? BorderSide(color: AppTheme.primaryOrange, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
