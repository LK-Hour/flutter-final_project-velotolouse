import 'dart:async';

import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/controllers/ride_timer_controller.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_google_map_canvas.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen map shown when the user taps "Start Ride" from [ActiveRideScreen].
///
/// Displays a live ride timer banner at the top, the user's current location
/// on the map (refreshed every 5 seconds), and an "End Ride" button at the
/// bottom.
class RideMapScreen extends StatefulWidget {
  const RideMapScreen({
    super.key,
    required this.rideTimer,
    required this.bikeCode,
    required this.stationName,
    required this.sessionId,
  });

  /// Shared timer that was already started on [ActiveRideScreen].
  final RideTimerController rideTimer;
  final String bikeCode;
  final String stationName;
  final String sessionId;

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  static const GeoCoordinate _defaultCenter = GeoCoordinate(
    latitude: 43.6046,
    longitude: 1.4442,
  );

  GeoCoordinate _mapCenter = _defaultCenter;
  GeoCoordinate? _userLocation;
  int _locateRequestVersion = 0;
  Timer? _locationRefreshTimer;
  bool _isEndingRide = false;
  bool _depsInitialized = false;

  // All Provider dependencies captured once in didChangeDependencies.
  late UserLocationRepository _locationRepo;
  late RideRepository _rideRepo;
  late BikeRepository _bikeRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _locationRepo = context.read<UserLocationRepository>();
      _rideRepo = context.read<RideRepository>();
      _bikeRepo = context.read<BikeRepository>();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.rideTimer.addListener(_onTimerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLocation());
    _locationRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLocation(),
    );
  }

  void _onTimerTick() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshLocation() async {
    if (!mounted) return;
    final UserLocationResult result = await _locationRepo.getCurrentLocation();
    if (!mounted) return;
    if (result.status == UserLocationStatus.located &&
        result.coordinate != null) {
      setState(() {
        _userLocation = result.coordinate;
        _mapCenter = result.coordinate!;
        _locateRequestVersion++;
      });
    }
  }

  @override
  void dispose() {
    widget.rideTimer.removeListener(_onTimerTick);
    _locationRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _onEndRide() async {
    if (_isEndingRide) return;
    setState(() => _isEndingRide = true);
    _locationRefreshTimer?.cancel();
    widget.rideTimer.pause();
    // Capture the navigator BEFORE any await so we never touch context after
    // the widget may have been removed from the tree.
    final NavigatorState navigator = Navigator.of(context);
    await Future.wait([
      _rideRepo.endRide(widget.sessionId),
      _bikeRepo.lockBike(widget.bikeCode),
    ]);
    navigator.popUntil((Route<dynamic> r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // ── Full-screen map ──────────────────────────────────────────────
          Positioned.fill(
            child: StationGoogleMapCanvas(
              stations: const [],
              isReturnMode: false,
              selectedStation: null,
              mapCenter: _mapCenter,
              currentUserLocation: _userLocation,
              locateRequestVersion: _locateRequestVersion,
              onStationTap: (_) {},
              fallbackMarkerPositions: const {},
            ),
          ),

          // ── Timer banner ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Ride in progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        widget.rideTimer.formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── End Ride button ──────────────────────────────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomPadding + 24,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEndingRide ? null : _onEndRide,
                icon: _isEndingRide
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.stop_circle_outlined),
                label: const Text(
                  'End Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.warning.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
