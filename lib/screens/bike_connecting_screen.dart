import 'dart:async';
import 'package:final_project_velotolouse/screens/active_ride_screen.dart';
import 'package:final_project_velotolouse/ui/controllers/ride_timer_controller.dart';
import 'package:final_project_velotolouse/ui/routing/app_router.dart';
import 'package:flutter/material.dart';
import '../themes/theme.dart';

/// Screen shown after QR detection while connecting to bike
class BikeConnectingScreen extends StatefulWidget {
  final String bikeCode;
  final String stationName;

  const BikeConnectingScreen({
    super.key,
    required this.bikeCode,
    required this.stationName,
  });

  @override
  State<BikeConnectingScreen> createState() => _BikeConnectingScreenState();
}

class _BikeConnectingScreenState extends State<BikeConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _completeTimer;
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

    // Navigate to active ride dashboard after 2-second simulated connection.
    _completeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.activeRide,
          arguments: ActiveRideArgs(
            bikeCode: widget.bikeCode,
            stationName: widget.stationName,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _completeTimer?.cancel();
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
                        ? AppTheme.primaryOrange
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
                        ? AppTheme.primaryOrange
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
                      color: AppTheme.successGreen,
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
                              color: AppTheme.primaryOrange,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
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
                            color: AppTheme.primaryOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pedal_bike,
                            color: AppTheme.primaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bike #${widget.bikeCode} • Slot 1',
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
                ? AppTheme.successGreen
                : isCurrent
                ? AppTheme.primaryOrange
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

/// Final unlock success screen (now shows active ride)
class _UnlockSuccessScreen extends StatefulWidget {
  final String bikeCode;
  final String stationName;

  const _UnlockSuccessScreen({
    required this.bikeCode,
    required this.stationName,
  });

  @override
  State<_UnlockSuccessScreen> createState() => _UnlockSuccessScreenState();
}

class _UnlockSuccessScreenState extends State<_UnlockSuccessScreen> {
  late final RideTimerController _rideTimer;

  @override
  void initState() {
    super.initState();
    _rideTimer = RideTimerController()..start();
    // Rebuild the UI on every timer tick.
    _rideTimer.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _rideTimer.dispose();
    super.dispose();
  }

  String get _formattedTime => _rideTimer.formattedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Green gradient background at top
          Container(
            height: 400,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Success checkmark icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Bike Unlocked! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Your ride has started. Have a safe trip!',
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Three dots progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // White card with ride details
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bike header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pedal_bike,
                                  color: AppTheme.primaryOrange,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bike #${widget.bikeCode}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Slot 1 - ${widget.stationName}',
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
                          const SizedBox(height: 8),

                          // Active status
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Ride Details section
                          const Text(
                            'Ride Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _formattedTime,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryOrange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Elapsed Time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '0.0 km',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Quick Actions section
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Lock Bike',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFE5E5),
                                    foregroundColor: const Color(0xFFE53935),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Report Issue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // End Ride button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // Go back to map
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryOrange,
                                side: const BorderSide(
                                  color: AppTheme.primaryOrange,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'End Ride',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Start Riding button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Go back to map
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Start Riding',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom navigation bar
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavBarItem(
                        icon: Icons.directions_bike,
                        label: 'Ride',
                        isActive: true,
                      ),
                      const SizedBox(width: 80), // Space for FAB
                      _NavBarItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        isActive: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button in center with QR icon
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppTheme.primaryOrange : Colors.grey[400],
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppTheme.primaryOrange : Colors.grey[400],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
