import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/services/ride_service.dart';
import 'package:final_project_velotolouse/services/station_service.dart';
import 'package:final_project_velotolouse/ui/states/ride_state.dart';
import 'package:final_project_velotolouse/ui/states/station_state.dart';
import 'package:flutter/foundation.dart';

// Re-export so screens can reference ReturnBikeResult from one import.
export 'package:final_project_velotolouse/services/ride_service.dart'
    show ReturnBikeResult;

enum StationNavigationResult {
  opened,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  locationUnavailable,
  launcherUnavailable,
}

/// Thin coordination ViewModel for the Station Map screen.
///
/// Architecture (5-layer BlaBla pattern):
///   • Delegates station data   → StationState
///   • Delegates ride data      → RideState
///   • Delegates business logic → StationService / RideService
///   • Owns only screen-specific state (route path, map-center override)
class StationMapViewModel extends ChangeNotifier {
  StationMapViewModel({
    required RideState rideState,
    required StationState stationState,
    required StationService stationService,
    required RideService rideService,
    required BikeRepository bikeRepository,
    UserLocationRepository? userLocationRepository,
    NavigationLauncherRepository? navigationLauncherRepository,
    StationRouteRepository? stationRouteRepository,
  })  : _rideState = rideState,
        _stationState = stationState,
        _stationService = stationService,
        _rideService = rideService,
        _bikeRepository = bikeRepository,
        _userLocationRepository =
            userLocationRepository ??
            const _UnavailableUserLocationRepository(),
        _navigationLauncherRepository =
            navigationLauncherRepository ??
            const _UnavailableNavigationLauncherRepository(),
        _stationRouteRepository =
            stationRouteRepository ?? const _EmptyStationRouteRepository() {
    _rideState.addListener(_onStateChanged);
    _stationState.addListener(_onStateChanged);
  }

  final RideState _rideState;
  final StationState _stationState;
  final StationService _stationService;
  final RideService _rideService;
  final BikeRepository _bikeRepository;
  final UserLocationRepository _userLocationRepository;
  final NavigationLauncherRepository _navigationLauncherRepository;
  final StationRouteRepository _stationRouteRepository;

  // Screen-specific state (not suitable for global StationState)
  GeoCoordinate? _mapCenterOverride;
  List<GeoCoordinate> _activeRoutePath = const <GeoCoordinate>[];
  int _locateVersionExtra = 0;

  // ─── Getters delegating to StationState ──────────────────────────────────

  bool get isLoading => _stationState.isLoading;
  String? get errorMessage => _stationState.errorMessage;
  List<Station> get stations => _stationState.stations;
  Station? get selectedStation => _stationState.selectedStation;
  GeoCoordinate get mapCenter =>
      _mapCenterOverride ?? _stationState.mapCenter;
  GeoCoordinate? get currentUserLocation => _stationState.currentUserLocation;
  int get locateRequestVersion =>
      _stationState.locateRequestVersion + _locateVersionExtra;
  List<GeoCoordinate> get activeRoutePath =>
      List<GeoCoordinate>.unmodifiable(_activeRoutePath);

  // ─── Getters delegating to RideState ─────────────────────────────────────

  bool get hasActiveRide => _rideState.hasActiveRide;
  bool get isReturnMode => _rideState.hasActiveRide;
  String? get activeRideBikeCode => _rideState.activeRide?.bikeCode;
  DateTime? get activeRideStartedAt => _rideState.activeRide?.startedAt;
  String? get activeRideSessionId => _rideState.activeRide?.id;

  /// Looks up the station name from the active ride's stationId.
  String? get activeRideStationName {
    final String? stationId = _rideState.activeRide?.stationId;
    if (stationId == null) return null;
    return _stationService
        .findStationById(_stationState.stations, stationId)
        ?.name;
  }

  // ─── Computed properties using services ──────────────────────────────────

  bool get showReturnModeBanner => _rideService.shouldShowReturnBanner(
    hasActiveRide: _rideState.hasActiveRide,
    isBannerDismissed: _rideState.isReturnBannerDismissed,
  );

  bool get showFullStationRerouteAlert => _rideService.shouldShowFullStationAlert(
    isReturnMode: isReturnMode,
    selectedStation: _stationState.selectedStation,
  );

  bool get showEmptyStationRerouteAlert {
    final Station? station = _stationState.selectedStation;
    return !isReturnMode && station != null && station.availableBikes == 0;
  }

  Station? get suggestedAlternativeDockStation {
    if (!showFullStationRerouteAlert) return null;
    return _stationService.findNearestStationWithDocks(
      _stationState.selectedStation!,
      _stationState.stations,
    );
  }

  Station? get suggestedAlternativeBikeStation {
    if (!showEmptyStationRerouteAlert) return null;
    return _findNearestStation(
      selected: _stationState.selectedStation!,
      isCandidate: (Station s) => s.availableBikes > 0,
    );
  }

  // ─── Actions delegating to StationState ──────────────────────────────────

  Future<void> loadStations() => _stationState.loadStations();

  void selectStation(String stationId) =>
      _stationState.selectStation(stationId);

  void clearSelectedStation() => _stationState.clearSelectedStation();

  // ─── Actions delegating to RideState ─────────────────────────────────────

  void dismissReturnModeBanner() => _rideState.dismissReturnBanner();

  // ─── Actions using services ───────────────────────────────────────────────

  List<Station> searchStations(String query) =>
      _stationService.searchStations(
        _stationState.stations,
        query,
        isReturnMode: isReturnMode,
      );

  bool hasAvailabilityForCurrentMode(Station station) =>
      _stationService.hasAvailability(station, isReturnMode: isReturnMode);

  String availabilityLabelForCurrentMode(Station station) =>
      _stationService.getAvailabilityLabel(station, isReturnMode: isReturnMode);

  // ─── Reroute helpers ─────────────────────────────────────────────────────

  void rerouteToSuggestedDock() {
    final Station? s = suggestedAlternativeDockStation;
    if (s != null) _stationState.selectStation(s.id);
  }

  void rerouteToSuggestedBikeStation() {
    final Station? s = suggestedAlternativeBikeStation;
    if (s != null) _stationState.selectStation(s.id);
  }

  // ─── Location & route (screen-specific) ──────────────────────────────────

  /// Centers the map on the user's current location.
  Future<UserLocationStatus> locateCurrentUser() async {
    _mapCenterOverride = null;
    _activeRoutePath = const <GeoCoordinate>[];
    return _stationState.locateCurrentUser();
  }

  /// Fetches a cycling route to [station] and centers the map on it.
  Future<UserLocationStatus> showRouteToStation(Station station) async {
    final UserLocationResult originResult =
        await _userLocationRepository.getCurrentLocation();
    if (originResult.status != UserLocationStatus.located ||
        originResult.coordinate == null) {
      return originResult.status;
    }

    final GeoCoordinate destination = GeoCoordinate(
      latitude: station.latitude,
      longitude: station.longitude,
    );
    final List<GeoCoordinate> roadRoute =
        await _stationRouteRepository.fetchCyclingRoute(
          origin: originResult.coordinate!,
          destination: destination,
        );

    _mapCenterOverride = destination;
    _activeRoutePath = roadRoute.length >= 2
        ? roadRoute
        : <GeoCoordinate>[originResult.coordinate!, destination];
    _locateVersionExtra += 1;
    notifyListeners();
    return UserLocationStatus.located;
  }

  bool focusOnStation(String stationId) {
    final Station? station =
        _stationService.findStationById(_stationState.stations, stationId);
    if (station == null) return false;
    _mapCenterOverride = GeoCoordinate(
      latitude: station.latitude,
      longitude: station.longitude,
    );
    _locateVersionExtra += 1;
    notifyListeners();
    return true;
  }

  // ─── Coordination: return bike ────────────────────────────────────────────

  /// Validates, calls Firebase, and updates both global states.
  ///
  /// Returns [ReturnBikeResult.success] on success, or a failure reason.
  Future<ReturnBikeResult> returnBikeToStation(Station station) async {
    final ReturnBikeResult validation = _rideService.validateReturn(
      hasActiveRide: _rideState.hasActiveRide,
      station: station,
    );
    if (validation != ReturnBikeResult.success) return validation;

    final activeRide = _rideState.activeRide;
    if (activeRide == null) return ReturnBikeResult.noActiveRide;

    // Run Firebase calls in parallel: end ride session + lock bike.
    await Future.wait(<Future<dynamic>>[
      _rideState.endActiveRide(),
      _bikeRepository.lockBike(
        activeRide.bikeCode,
        returnStationId: station.id,
      ),
    ]);

    // Update local station availability.
    _stationState.updateStationAfterReturn(station.id);
    _activeRoutePath = const <GeoCoordinate>[];
    _mapCenterOverride = null;
    return ReturnBikeResult.success;
  }

  // ─── Navigation (launch external maps app) ───────────────────────────────

  Future<StationNavigationResult> navigateToStation(Station station) async {
    if (kIsWeb) {
      final bool didOpen = await _navigationLauncherRepository.openDirections(
        destination: GeoCoordinate(
          latitude: station.latitude,
          longitude: station.longitude,
        ),
      );
      return didOpen
          ? StationNavigationResult.opened
          : StationNavigationResult.launcherUnavailable;
    }

    final UserLocationResult originResult =
        await _userLocationRepository.getCurrentLocation();
    if (originResult.status != UserLocationStatus.located ||
        originResult.coordinate == null) {
      return _navigationResultFromLocationStatus(originResult.status);
    }

    final bool didOpen = await _navigationLauncherRepository.openDirections(
      origin: originResult.coordinate!,
      destination: GeoCoordinate(
        latitude: station.latitude,
        longitude: station.longitude,
      ),
    );
    return didOpen
        ? StationNavigationResult.opened
        : StationNavigationResult.launcherUnavailable;
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _rideState.removeListener(_onStateChanged);
    _stationState.removeListener(_onStateChanged);
    super.dispose();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  void _onStateChanged() => notifyListeners();

  Station? _findNearestStation({
    required Station selected,
    required bool Function(Station) isCandidate,
  }) {
    Station? nearest;
    double? nearestDist;
    for (final Station s in _stationState.stations) {
      if (s.id == selected.id || !isCandidate(s)) continue;
      final double d = _distanceSquared(selected, s);
      if (nearest == null || d < nearestDist!) {
        nearest = s;
        nearestDist = d;
      }
    }
    return nearest;
  }

  double _distanceSquared(Station a, Station b) {
    final double dx = a.latitude - b.latitude;
    final double dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  StationNavigationResult _navigationResultFromLocationStatus(
    UserLocationStatus status,
  ) {
    return switch (status) {
      UserLocationStatus.permissionDenied =>
        StationNavigationResult.permissionDenied,
      UserLocationStatus.permissionDeniedForever =>
        StationNavigationResult.permissionDeniedForever,
      UserLocationStatus.serviceDisabled =>
        StationNavigationResult.serviceDisabled,
      UserLocationStatus.unavailable =>
        StationNavigationResult.locationUnavailable,
      UserLocationStatus.located => StationNavigationResult.locationUnavailable,
    };
  }
}

// ─── Null-object stubs for optional dependencies ─────────────────────────────

class _UnavailableUserLocationRepository implements UserLocationRepository {
  const _UnavailableUserLocationRepository();

  @override
  Future<UserLocationResult> getCurrentLocation() async =>
      const UserLocationResult(status: UserLocationStatus.unavailable);
}

class _UnavailableNavigationLauncherRepository
    implements NavigationLauncherRepository {
  const _UnavailableNavigationLauncherRepository();

  @override
  Future<bool> openDirections({
    GeoCoordinate? origin,
    required GeoCoordinate destination,
  }) async => false;
}

class _EmptyStationRouteRepository implements StationRouteRepository {
  const _EmptyStationRouteRepository();

  @override
  Future<List<GeoCoordinate>> fetchCyclingRoute({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  }) async => const <GeoCoordinate>[];
}
