import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/screens/active_ride/active_ride_screen.dart';
import 'package:final_project_velotolouse/ui/screens/bike_connecting/bike_connecting_screen.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'web_camera_stub.dart' if (dart.library.html) 'web_camera_impl.dart';

/// QR Scanner Screen with working scan detection and unlock success flow
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.showDemoScanButton = false});

  final bool showDemoScanButton;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.front,
  );
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFlashOn = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // On web, start the HTML5 camera feed with QR detection
    if (kIsWeb) {
      initWebCamera(onQrDetected: _handleCodeFound);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      disposeWebCamera();
    } else {
      _scannerController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _handleCodeFound(barcode!.rawValue!);
    }
  }

  Future<void> _handleCodeFound(String code) async {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);
    _animationController.stop();

    // If a ride is already active, redirect to it instead of creating another.
    final rideRepo = context.read<RideRepository>();
    final bikeRepo = context.read<BikeRepository>();
    final activeRide = await rideRepo.getActiveRide();

    if (!mounted) return;

    if (widget.showDemoScanButton) {
      final activeSession =
          activeRide ??
          await rideRepo.startRide(
            bikeCode: code,
            stationId: 'capitole-square',
          );

      if (activeRide == null) {
        await bikeRepo.unlockBike(code);
      }

      try {
        context.read<StationMapViewModel>().activateRide(
          sessionId: activeSession.id,
          startedAt: activeSession.startedAt,
          bikeCode: activeSession.bikeCode,
          stationName: 'Capitole Square',
        );
      } catch (_) {
        // Screen may be used outside station map flow.
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: activeSession.bikeCode,
            stationName: 'Capitole Square',
            sessionId: activeSession.id,
          ),
        ),
      );
      return;
    }

    if (activeRide != null) {
      try {
        context.read<StationMapViewModel>().activateRide(
          sessionId: activeRide.id,
          startedAt: activeRide.startedAt,
          bikeCode: activeRide.bikeCode,
          stationName: 'Capitole Square',
        );
      } catch (_) {
        // Screen may be used outside station map flow.
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an active ride. Resuming it now.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: activeRide.bikeCode,
            stationName: 'Capitole Square',
            sessionId: activeRide.id,
          ),
        ),
      );
      return;
    }

    // Validate bike exists in the repository before proceeding.
    final slot = await bikeRepo.getBikeByCode(code);

    if (!mounted) return;

    if (slot == null) {
      // Unknown code — reset so the user can try again.
      setState(() => _hasScanned = false);
      _animationController.repeat(reverse: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bike "$code" not found. Please scan again.'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    try {
      context.read<StationMapViewModel>().setHasActiveRide(true);
    } catch (_) {
      // Screen may be used outside station map flow.
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BikeConnectingScreen(
          bikeCode: code,
          stationName: 'Capitole Square',
          connectionDelay: widget.showDemoScanButton
              ? Duration.zero
              : const Duration(seconds: 2),
        ),
      ),
    );
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    _scannerController.toggleTorch();
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Bike Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'e.g., CO-04',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.warning, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(ctx);
                _handleCodeFound(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Unlock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 80,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: _toggleFlash,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: _isFlashOn ? Colors.amber : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Flash',
                      style: TextStyle(
                        color: _isFlashOn ? Colors.amber : Colors.white,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen camera feed (behind everything)
          Positioned.fill(
            child: kIsWeb
                ? const WebCameraView()
                : widget.showDemoScanButton
                ? Container(color: Colors.black87)
                : MobileScanner(
                    controller: _scannerController,
                    onDetect: _onQrDetected,
                  ),
          ),

          // Dark overlay with transparent cutout
          CustomPaint(painter: _QrScannerOverlayPainter(), child: Container()),

          // Orange corner borders and scanning line
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 120),
              width: 340,
              height: 340,
              child: Stack(
                children: [
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBorder(isTopLeft: true),
                  ),
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerBorder(isTopRight: true),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerBorder(isBottomLeft: true),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerBorder(isBottomRight: true),
                  ),
                  // Animated scanning line (only while searching)
                  if (!_hasScanned)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value * 340,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom scanning info sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.97),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Station name + searching status on one compact row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scanning for',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Capitole Square',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _hasScanned ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _hasScanned ? 'Found!' : 'Searching...',
                              style: TextStyle(
                                fontSize: 13,
                                color: _hasScanned ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action button(s)
                    Center(
                      child: (kIsWeb || widget.showDemoScanButton)
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: () => _handleCodeFound('CO-04'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '⚡  Simulate QR Scan (Demo)',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showManualEntryDialog,
                                  child: Text(
                                    'Enter bike code manually',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: _showManualEntryDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Enter bike code manually',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final cutoutSize = 340.0;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, (size.height / 2) - 60),
      width: cutoutSize,
      height: cutoutSize,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)))
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          top: (isTopLeft || isTopRight)
              ? const BorderSide(color: AppColors.warning, width: 4)
              : BorderSide.none,
          left: (isTopLeft || isBottomLeft)
              ? const BorderSide(color: AppColors.warning, width: 4)
              : BorderSide.none,
          right: (isTopRight || isBottomRight)
              ? const BorderSide(color: AppColors.warning, width: 4)
              : BorderSide.none,
          bottom: (isBottomLeft || isBottomRight)
              ? const BorderSide(color: AppColors.warning, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
