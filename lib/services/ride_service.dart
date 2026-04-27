import 'package:final_project_velotolouse/domain/model/stations/ride_session.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';

/// Result of attempting to return a bike to a station.
enum ReturnBikeResult { 
  /// Successfully returned the bike.
  success, 
  
  /// No active ride to return.
  noActiveRide, 
  
  /// Station has no free docks.
  stationFull 
}

/// Service layer for ride-related business logic.
/// 
/// Handles:
/// - Ride state validation
/// - Return bike logic and validation
/// - Ride session management
class RideService {
  /// Validates if a bike can be returned to a station.
  /// 
  /// Returns [ReturnBikeResult] indicating success or the reason for failure.
  ReturnBikeResult validateReturn({
    required bool hasActiveRide,
    required Station station,
  }) {
    if (!hasActiveRide) {
      return ReturnBikeResult.noActiveRide;
    }
    
    if (station.freeDocks <= 0) {
      return ReturnBikeResult.stationFull;
    }
    
    return ReturnBikeResult.success;
  }

  /// Checks if the return mode banner should be shown.
  bool shouldShowReturnBanner({
    required bool hasActiveRide,
    required bool isBannerDismissed,
  }) {
    return hasActiveRide && !isBannerDismissed;
  }

  /// Checks if the full station alert should be shown.
  bool shouldShowFullStationAlert({
    required bool isReturnMode,
    required Station? selectedStation,
  }) {
    return isReturnMode &&
        selectedStation != null &&
        selectedStation.freeDocks == 0;
  }

  /// Calculates elapsed time for a ride session.
  Duration calculateElapsedTime(RideSession session) {
    final DateTime end = session.endedAt ?? DateTime.now();
    return end.difference(session.startedAt);
  }
}
