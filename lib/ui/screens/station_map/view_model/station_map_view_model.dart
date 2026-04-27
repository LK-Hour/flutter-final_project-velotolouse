import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/services/ride_service.dart';
import 'package:final_project_velotolouse/services/station_service.dart';
import 'package:final_project_velotolouse/ui/states/ride_state.dart';
import 'package:final_project_velotolouse/ui/states/station_state.dart';
import 'package:flutter/foundation.dart';

export 'package:final_project_velotolouse/services/ride_service.dart' show ReturnBikeResult;

/// ViewModel for Station Map Screen.
/// 
/// Follows the MVVM pattern with global states:
/// - Listens to [RideState] and [StationState] for data changes
/// - Delegates business logic to [StationService] and [RideService]
/// - Coordinates between global states and UI
/// 
/// This approach provides:
/// - Cleaner separation of concerns
/// - Reusable business logic in services
/// - Shared state across multiple screens
class StationMapViewModel extends ChangeNotifier {
  final RideState _rideState;
  final StationState _stationState;
  final StationService _stationService;
  final RideService _rideService;

  StationMapViewModel({
    required RideState rideState,
    required StationState stationState,
    required StationService stationService,
    required RideService rideService,
  })  : _rideState = rideState,
        _stationState = stationState,
        _stationService = stationService,
        _rideService = rideService {
    // Listen to global state changes
    _rideState.addListener(_onStateChanged);
    _stationState.addListener(_onStateChanged);
  }

  /// Called when global states change - triggers UI rebuild.
  void _onStateChanged() {
    notifyListeners();
  }

  // Getters - expose data from global states
  bool get isLoading => _stationState.isLoading;
  String? get errorMessage => _stationState.errorMessage;
  List<Station> get stations => _stationState.stations;
  Station? get selectedStation => _stationState.selectedStation;
  bool get hasActiveRide => _rideState.hasActiveRide;
  bool get isReturnMode => _rideState.isReturnMode;
  GeoCoordinate get mapCenter => _stationState.mapCenter;
  GeoCoordinate? get currentUserLocation => _stationState.currentUserLocation;
  int get locateRequestVersion => _stationState.locateRequestVersion;

  bool get showReturnModeBanner {
    return _rideService.shouldShowReturnBanner(
      hasActiveRide: _rideState.hasActiveRide,
      isBannerDismissed: _rideState.isReturnBannerDismissed,
    );
  }

  bool get showFullStationRerouteAlert {
    return _rideService.shouldShowFullStationAlert(
      isReturnMode: isReturnMode,
      selectedStation: _stationState.selectedStation,
    );
  }

  Station? get suggestedAlternativeDockStation {
    if (!showFullStationRerouteAlert || _stationState.selectedStation == null) {
      return null;
    }
    
    return _stationService.findNearestStationWithDocks(
      _stationState.selectedStation!,
      _stationState.stations,
    );
  }

  // Actions - delegate to global states
  Future<void> loadStations() => _stationState.loadStations();

  void selectStation(String stationId) => _stationState.selectStation(stationId);

  void clearSelectedStation() => _stationState.clearSelectedStation();

  void setHasActiveRide(bool value) => _rideState.setHasActiveRide(value);

  bool activateRideFromScan() => _rideState.activateFromScan();

  Future<bool> endActiveRide() => _rideState.endActiveRide();

  bool dismissReturnModeBanner() => _rideState.dismissReturnBanner();

  Future<UserLocationStatus> locateCurrentUser() =>
      _stationState.locateCurrentUser();

  /// Returns a bike to a station.
  /// 
  /// Validates the return, updates station availability, and ends the ride.
  ReturnBikeResult returnBikeToStation(Station station) {
    final result = _rideService.validateReturn(
      hasActiveRide: _rideState.hasActiveRide,
      station: station,
    );

    if (result != ReturnBikeResult.success) {
      return result;
    }

    // Update station availability
    _stationState.updateStationAfterReturn(station.id);

    // End the active ride
    _rideState.endActiveRide();

    return ReturnBikeResult.success;
  }

  /// Toggles return mode for testing purposes.
  void toggleReturnModeForTesting() {
    _rideState.setHasActiveRide(!_rideState.hasActiveRide);
  }

  /// Reroutes to the suggested alternative station.
  void rerouteToSuggestedDock() {
    final Station? suggestion = suggestedAlternativeDockStation;
    if (suggestion == null) {
      return;
    }
    _stationState.selectStation(suggestion.id);
  }

  // Business logic delegates - use services
  bool hasAvailabilityForCurrentMode(Station station) {
    return _stationService.hasAvailability(
      station,
      isReturnMode: isReturnMode,
    );
  }

  String availabilityLabelForCurrentMode(Station station) {
    return _stationService.getAvailabilityLabel(
      station,
      isReturnMode: isReturnMode,
    );
  }

  List<Station> searchStations(String query) {
    return _stationService.searchStations(
      _stationState.stations,
      query,
      isReturnMode: isReturnMode,
    );
  }

  @override
  void dispose() {
    // Unlisten from global states to prevent memory leaks
    _rideState.removeListener(_onStateChanged);
    _stationState.removeListener(_onStateChanged);
    super.dispose();
  }
}
