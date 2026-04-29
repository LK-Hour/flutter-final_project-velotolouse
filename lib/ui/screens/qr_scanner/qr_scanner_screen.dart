import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/screens/active_ride/active_ride_screen.dart';
import 'package:final_project_velotolouse/ui/screens/bike_connecting/bike_connecting_screen.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/instant_payment_screen.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/passes/daily_pass_screen.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'web_camera_stub.dart' if (dart.library.html) 'web_camera_impl.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    this.showDemoScanButton = false,
    this.bikeCode,
    this.stationId,
    this.stationName,
  });

  final bool showDemoScanButton;
  final String? bikeCode;
  final String? stationId;
  final String? stationName;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
  );

  late final AnimationController _animationController;
  late final Animation<double> _animation;
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
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _handleCodeFound(rawValue);
    }
  }

  Future<void> _handleCodeFound(String code) async {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);
    _animationController.stop();

    final String effectiveCode = widget.bikeCode ?? code;
    final String effectiveStationId = widget.stationId ?? 'capitole-square';
    final String effectiveStationName = widget.stationName ?? 'Capitole Square';

    final rideRepo = context.read<RideRepository>();
    final bikeRepo = context.read<BikeRepository>();
    final activeRide = await rideRepo.getActiveRide();

    if (!mounted) return;

    if (widget.showDemoScanButton) {
      final activeSession =
          activeRide ??
          await rideRepo.startRide(
            bikeCode: effectiveCode,
            stationId: effectiveStationId,
          );

      if (activeRide == null) {
        await bikeRepo.unlockBike(effectiveCode);
      }

      try {
        context.read<StationMapViewModel>().activateRide(
          sessionId: activeSession.id,
          startedAt: activeSession.startedAt,
          bikeCode: activeSession.bikeCode,
          stationName: effectiveStationName,
        );
      } catch (_) {
        // Screen may be used outside station map flow.
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: activeSession.bikeCode,
            stationName: effectiveStationName,
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
          stationName: effectiveStationName,
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
            stationName: effectiveStationName,
            sessionId: activeRide.id,
          ),
        ),
      );
      return;
    }

    final slot = await bikeRepo.getBikeByCode(effectiveCode);
    if (!mounted) return;

    if (slot == null) {
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
          bikeCode: effectiveCode,
          stationName: effectiveStationName,
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

  void _showDemoPaymentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Insufficient balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how to continue the demo before scanning the bike again.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E8E)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InstantPaymentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Demo Instant Topup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DailyPassScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.card_membership_outlined),
                    label: const Text('View Subscription Plans'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(
                        color: AppColors.warning,
                        width: 1.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          CustomPaint(painter: _QrScannerOverlayPainter(), child: Container()),
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 120),
              width: 340,
              height: 340,
              child: Stack(
                children: [
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBorder(isTopLeft: true),
                  ),
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerBorder(isTopRight: true),
                  ),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerBorder(isBottomLeft: true),
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerBorder(isBottomRight: true),
                  ),
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
                            Text(
                              widget.stationName ?? 'Capitole Square',
                              style: const TextStyle(
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
                    Center(
                      child: (kIsWeb || widget.showDemoScanButton)
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleCodeFound(
                                      widget.bikeCode ?? 'CO-04',
                                    ),
                                    icon: const Icon(
                                      Icons.flash_on_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Simulate QR Scan (Book)',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warning,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: _showDemoPaymentOptions,
                                    icon: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Simulate Instant Topup / Subscription',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.warning,
                                      side: const BorderSide(
                                        color: AppColors.warning,
                                        width: 1.6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                    const SizedBox(height: 14),
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

class _QrScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRect(Offset.zero & size, dimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBorder extends StatelessWidget {
  const _CornerBorder({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.warning;
    const cornerSize = 34.0;
    const strokeWidth = 4.0;

    final topLeft = isTopLeft;
    final topRight = isTopRight;
    final bottomLeft = isBottomLeft;
    final bottomRight = isBottomRight;

    return SizedBox(
      width: cornerSize,
      height: cornerSize,
      child: CustomPaint(
        painter: _CornerPainter(
          color: borderColor,
          strokeWidth: strokeWidth,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Color color;
  final double strokeWidth;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    if (topLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
    }
    if (topRight) {
      canvas.drawLine(
        Offset.zero.translate(0, 0),
        Offset(size.width, 0),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
    }
    if (bottomLeft) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.topLeft != topLeft ||
        oldDelegate.topRight != topRight ||
        oldDelegate.bottomLeft != bottomLeft ||
        oldDelegate.bottomRight != bottomRight;
  }
}
