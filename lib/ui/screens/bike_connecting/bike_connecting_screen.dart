import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/screens/active_ride/active_ride_screen.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen shown after QR detection while connecting to bike
class BikeConnectingScreen extends StatefulWidget {
  final String bikeCode;
  final String stationName;
  final Duration connectionDelay;

  const BikeConnectingScreen({
    super.key,
    required this.bikeCode,
    required this.stationName,
    this.connectionDelay = const Duration(seconds: 2),
  });

  @override
  State<BikeConnectingScreen> createState() => _BikeConnectingScreenState();
}

class _BikeConnectingScreenState extends State<BikeConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  int _currentStep = 1; // 0=QR scanned, 1=Verifying, 2=Unlocking

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start progress animation
    _progressController.forward();

    // Update step when progress reaches 50%
    _progressController.addListener(() {
      if (_progressController.value >= 0.5 && _currentStep == 1) {
        setState(() => _currentStep = 2);
      }
    });

    // Unlock the bike and start the ride session (minimum 2s for UX).
    _connect();
  }

  Future<void> _connect() async {
    final bikeRepo = context.read<BikeRepository>();
    final rideRepo = context.read<RideRepository>();

    final existingSession = await rideRepo.getActiveRide();
    if (existingSession != null) {
      if (!mounted) return;
      try {
        context.read<StationMapViewModel>().setHasActiveRide(true);
      } catch (_) {
        // Screen may be used outside station map flow.
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: existingSession.bikeCode,
            stationName: widget.stationName,
            sessionId: existingSession.id,
          ),
        ),
      );
      return;
    }

    // Run unlock + session creation + minimum delay in parallel.
    final sessionFuture = rideRepo.startRide(
      bikeCode: widget.bikeCode,
      stationId: 'capitole-square',
    );
    await Future.wait([
      bikeRepo.unlockBike(widget.bikeCode),
      sessionFuture,
      if (widget.connectionDelay > Duration.zero)
        Future.delayed(widget.connectionDelay)
      else
        Future<void>.value(),
    ]);
    final session = await sessionFuture;

    if (mounted) {
      try {
        context.read<StationMapViewModel>().setHasActiveRide(true);
      } catch (_) {
        // Screen may be used outside station map flow.
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: widget.bikeCode,
            stationName: widget.stationName,
            sessionId: session.id,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.grey[500],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scanning complete',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Progress stepper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                _StepIndicator(
                  label: 'QR scanned',
                  isComplete: true,
                  isCurrent: false,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 1
                        ? AppColors.warning
                        : Colors.grey[300],
                  ),
                ),
                _StepIndicator(
                  label: 'Verifying',
                  isComplete: _currentStep > 1,
                  isCurrent: _currentStep == 1,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 2
                        ? AppColors.warning
                        : Colors.grey[300],
                  ),
                ),
                _StepIndicator(
                  label: 'Unlocking',
                  isComplete: false,
                  isCurrent: _currentStep == 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // Connection card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'QR Code Detected!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Connecting to your bike...',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Progress bar with percentage
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final percentage = (_progressAnimation.value * 100)
                          .toInt();
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.grey[200],
                              color: AppColors.warning,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bike info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pedal_bike,
                            color: AppColors.warning,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bike #${widget.bikeCode} - Slot 1',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.stationName} Station',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel connection',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final bool isComplete;
  final bool isCurrent;

  const _StepIndicator({
    required this.label,
    required this.isComplete,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isComplete
                ? AppColors.success
                : isCurrent
                ? AppColors.warning
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: isComplete
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isComplete || isCurrent ? Colors.black87 : Colors.grey[500],
            fontWeight: isComplete || isCurrent
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
