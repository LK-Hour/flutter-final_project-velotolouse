import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/controllers/ride_timer_controller.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:final_project_velotolouse/ui/widgets/ride_completion_modal.dart';
import 'package:final_project_velotolouse/ui/widgets/animated_reveal_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Arguments passed to [ActiveRideScreen] via the named route.
class ActiveRideArgs {
  const ActiveRideArgs({
    required this.bikeCode,
    required this.stationName,
    required this.sessionId,
  });

  final String bikeCode;
  final String stationName;
  final String sessionId;
}

/// Active ride dashboard shown after a successful bike unlock.
///
/// Receives [ActiveRideArgs] as its route argument so it can be pushed
/// using [Navigator.pushReplacementNamed] with a typed argument object.
class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({
    super.key,
    required this.bikeCode,
    required this.stationName,
    required this.sessionId,
  });

  final String bikeCode;
  final String stationName;
  final String sessionId;

  /// Convenience factory that builds from a typed [ActiveRideArgs] object.
  factory ActiveRideScreen.fromArgs(ActiveRideArgs args) => ActiveRideScreen(
    bikeCode: args.bikeCode,
    stationName: args.stationName,
    sessionId: args.sessionId,
  );

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  late final RideTimerController _rideTimer;

  @override
  void initState() {
    super.initState();
    _rideTimer = RideTimerController()..start();
    _rideTimer.addListener(_onTick);
    _syncTimerFromActiveSession();
  }

  Future<void> _syncTimerFromActiveSession() async {
    final rideRepo = context.read<RideRepository>();
    final activeRide = await rideRepo.getActiveRide();
    if (!mounted || activeRide == null) {
      return;
    }

    _rideTimer.pause();
    _rideTimer.start(initialElapsed: activeRide.elapsed);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _showRideCompletionModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return RideCompletionModal(
          bikeCode: widget.bikeCode,
          stationName: widget.stationName,
          rideDuration: _formattedTime,
          onDone: () {
            Navigator.of(dialogContext).pop();
            Navigator.popUntil(
              context,
              (Route<dynamic> route) => route.isFirst,
            );
          },
        );
      },
    );
  }

  Future<void> _handleEndRidePressed() async {
    final rideRepo = context.read<RideRepository>();
    final bikeRepo = context.read<BikeRepository>();
    final stationMapViewModel = context.read<StationMapViewModel>();

    _rideTimer.pause();
    await Future.wait([
      rideRepo.endRide(widget.sessionId),
      bikeRepo.lockBike(widget.bikeCode, returnStationId: null),
    ]);
    stationMapViewModel.endActiveRide();

    if (!mounted) {
      return;
    }

    await _showRideCompletionModal();
  }

  @override
  void dispose() {
    _rideTimer
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  String get _formattedTime => _rideTimer.formattedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Green gradient header background
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

                // Checkmark icon
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
                  'Bike Unlocked!',
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

                // Dot indicator row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == 0
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Content card
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
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pedal_bike,
                                  color: AppColors.warning,
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

                          AnimatedRevealCard(
                            delay: const Duration(milliseconds: 120),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F4F1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE8D6CB),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bike Information',
                                    style: TextStyle(
                                      color: Color(0xFF6A4A3C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _BikeDetailRow(
                                    label: 'Bike code',
                                    value: widget.bikeCode,
                                  ),
                                  const SizedBox(height: 6),
                                  _BikeDetailRow(
                                    label: 'Station',
                                    value: widget.stationName,
                                  ),
                                  const SizedBox(height: 6),
                                  const _BikeDetailRow(
                                    label: 'Status',
                                    value: 'Active ride',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Active status indicator
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Ride Details
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
                                child: _StatBox(
                                  value: _formattedTime,
                                  label: 'Elapsed Time',
                                  valueColor: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  value: '0.0 km',
                                  label: 'Distance',
                                  valueColor: Colors.grey[800]!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Back to Home Screen
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                Navigator.popUntil(context, (r) => r.isFirst);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Back to Home Screen',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // End Ride
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _handleEndRidePressed,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  0,
                                  0,
                                ),
                                side: const BorderSide(
                                  color: AppColors.warning,
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
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom nav bar
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
                      const SizedBox(width: 80),
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

          // FAB — QR scanner icon
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

// ── Internal helpers ────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _BikeDetailRow extends StatelessWidget {
  const _BikeDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8F8F8F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF212121),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.warning : Colors.grey[400],
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.warning : Colors.grey[400],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
