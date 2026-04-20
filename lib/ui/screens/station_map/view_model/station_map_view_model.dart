import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:flutter/foundation.dart';

enum ReturnBikeResult { success, noActiveRide, stationFull }

enum StationNavigationResult {
  opened,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  locationUnavailable,
  launcherUnavailable,
}

class StationMapViewModel extends ChangeNotifier {
  StationMapViewModel({
    required StationRepository repository,
    UserLocationRepository? userLocationRepository,
    NavigationLauncherRepository? navigationLauncherRepository,
    StationRouteRepository? stationRouteRepository,
  }) : _repository = repository,
       _userLocationRepository =
           userLocationRepository ?? const _UnavailableUserLocationRepository(),
       _navigationLauncherRepository =
           navigationLauncherRepository ??
           const _UnavailableNavigationLauncherRepository(),
       _stationRouteRepository =
           stationRouteRepository ?? const _EmptyStationRouteRepository();

  final StationRepository _repository;
  final UserLocationRepository _userLocationRepository;
  final NavigationLauncherRepository _navigationLauncherRepository;
  final StationRouteRepository _stationRouteRepository;
  static const GeoCoordinate defaultMapCenter = GeoCoordinate(
    latitude: 11.5564,
    longitude: 104.9282,
  );

  bool _isLoading = false;
  String? _errorMessage;
  List<Station> _stations = <Station>[];
  Station? _selectedStation;
  bool _hasActiveRide = false;
  bool _isReturnBannerVisible = true;
  GeoCoordinate _mapCenter = defaultMapCenter;
  GeoCoordinate? _currentUserLocation;
  List<GeoCoordinate> _activeRoutePath = <GeoCoordinate>[];
  int _locateRequestVersion = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Station> get stations => List<Station>.unmodifiable(_stations);
  Station? get selectedStation => _selectedStation;
  bool get hasActiveRide => _hasActiveRide;
  bool get isReturnMode => _hasActiveRide;
  bool get showReturnModeBanner => isReturnMode && _isReturnBannerVisible;
  GeoCoordinate get mapCenter => _mapCenter;
  GeoCoordinate? get currentUserLocation => _currentUserLocation;
  List<GeoCoordinate> get activeRoutePath =>
      List<GeoCoordinate>.unmodifiable(_activeRoutePath);
  int get locateRequestVersion => _locateRequestVersion;
  bool get showFullStationRerouteAlert {
    return isReturnMode &&
        _selectedStation != null &&
        _selectedStation!.freeDocks == 0;
  }

  bool get showEmptyStationRerouteAlert {
    return !isReturnMode &&
        _selectedStation != null &&
        _selectedStation!.availableBikes == 0;
  }

  Station? get suggestedAlternativeDockStation {
    if (!showFullStationRerouteAlert) {
      return null;
    }

    return _findNearestStation(
      selected: _selectedStation!,
      isCandidate: (Station station) => station.freeDocks > 0,
    );
  }

  Station? get suggestedAlternativeBikeStation {
    if (!showEmptyStationRerouteAlert) {
      return null;
    }

    return _findNearestStation(
      selected: _selectedStation!,
      isCandidate: (Station station) => station.availableBikes > 0,
    );
  }

  Future<void> loadStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stations = await _repository.fetchStations();
      if (_selectedStation != null) {
        _selectedStation = _findStationById(_selectedStation!.id);
      }
    } on Exception {
      _errorMessage = 'Unable to load stations. Please try again.';
      _stations = <Station>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStation(String stationId) {
    final Station? station = _findStationById(stationId);
    if (station == null) {
      return;
    }
    _selectedStation = station;
    notifyListeners();
  }

  void clearSelectedStation() {
    if (_selectedStation == null) {
      return;
    }
    _selectedStation = null;
    notifyListeners();
  }

  void setHasActiveRide(bool value) {
    if (_hasActiveRide == value) {
      return;
    }
    _applyRideState(isActive: value);
    notifyListeners();
  }

  bool activateRideFromScan() {
    if (_hasActiveRide) {
      return false;
    }
    _applyRideState(isActive: true);
    notifyListeners();
    return true;
  }

  bool endActiveRide() {
    if (!_hasActiveRide) {
      return false;
    }
    _applyRideState(isActive: false);
    notifyListeners();
    return true;
  }

  ReturnBikeResult returnBikeToStation(Station station) {
    if (!_hasActiveRide) {
      return ReturnBikeResult.noActiveRide;
    }
    final Station? matchedStation = _findStationById(station.id);
    final Station targetStation = matchedStation ?? station;

    if (targetStation.freeDocks <= 0) {
      return ReturnBikeResult.stationFull;
    }
    if (matchedStation != null) {
      _stations = _stations
          .map((Station currentStation) {
            if (currentStation.id != matchedStation.id) {
              return currentStation;
            }
            return currentStation.copyWith(
              availableBikes: currentStation.availableBikes + 1,
            );
          })
          .toList(growable: false);
    }
    _applyRideState(isActive: false);
    notifyListeners();
    return ReturnBikeResult.success;
  }

  bool dismissReturnModeBanner() {
    if (!showReturnModeBanner) {
      return false;
    }
    _isReturnBannerVisible = false;
    notifyListeners();
    return true;
  }

  void toggleReturnModeForTesting() {
    _applyRideState(isActive: !_hasActiveRide);
    notifyListeners();
  }

  void rerouteToSuggestedDock() {
    final Station? suggestion = suggestedAlternativeDockStation;
    if (suggestion == null) {
      return;
    }
    _selectedStation = suggestion;
    notifyListeners();
  }

  void rerouteToSuggestedBikeStation() {
    final Station? suggestion = suggestedAlternativeBikeStation;
    if (suggestion == null) {
      return;
    }
    _selectedStation = suggestion;
    notifyListeners();
  }

  Future<UserLocationStatus> locateCurrentUser() async {
    final UserLocationResult result = await _userLocationRepository
        .getCurrentLocation();
    if (result.status != UserLocationStatus.located ||
        result.coordinate == null) {
      return result.status;
    }

    _mapCenter = result.coordinate!;
    _currentUserLocation = result.coordinate!;
    _locateRequestVersion += 1;
    notifyListeners();
    return UserLocationStatus.located;
  }

  Future<UserLocationStatus> showRouteToStation(Station station) async {
    final UserLocationResult originResult = await _userLocationRepository
        .getCurrentLocation();
    if (originResult.status != UserLocationStatus.located ||
        originResult.coordinate == null) {
      return originResult.status;
    }

    final GeoCoordinate destination = GeoCoordinate(
      latitude: station.latitude,
      longitude: station.longitude,
    );
    final List<GeoCoordinate> roadRoute = await _stationRouteRepository
        .fetchCyclingRoute(
          origin: originResult.coordinate!,
          destination: destination,
        );

    _currentUserLocation = originResult.coordinate!;
    _mapCenter = destination;
    _activeRoutePath = roadRoute.length >= 2
        ? roadRoute
        : <GeoCoordinate>[originResult.coordinate!, destination];
    _locateRequestVersion += 1;
    notifyListeners();
    return UserLocationStatus.located;
  }

  bool focusOnStation(String stationId) {
    final Station? station = _findStationById(stationId);
    if (station == null) {
      return false;
    }

    _mapCenter = GeoCoordinate(
      latitude: station.latitude,
      longitude: station.longitude,
    );
    notifyListeners();
    return true;
  }

  Future<StationNavigationResult> navigateToStation(Station station) async {
    if (kIsWeb) {
      final bool didOpen = await _navigationLauncherRepository.openDirections(
        destination: GeoCoordinate(
          latitude: station.latitude,
          longitude: station.longitude,
        ),
      );
      if (!didOpen) {
        return StationNavigationResult.launcherUnavailable;
      }
      return StationNavigationResult.opened;
    }

    final UserLocationResult originResult = await _userLocationRepository
        .getCurrentLocation();
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
    if (!didOpen) {
      return StationNavigationResult.launcherUnavailable;
    }
    return StationNavigationResult.opened;
  }

  bool hasAvailabilityForCurrentMode(Station station) {
    return isReturnMode ? station.freeDocks > 0 : station.availableBikes > 0;
  }

  String availabilityLabelForCurrentMode(Station station) {
    return isReturnMode
        ? '${station.freeDocks} Docks'
        : '${station.availableBikes} Bikes';
  }

  List<Station> searchStations(String query) {
    final String normalizedQuery = query.trim().toLowerCase();
    final List<Station> results = _stations
        .where((Station station) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          final String name = station.name.toLowerCase();
          final String address = station.address.toLowerCase();
          return name.contains(normalizedQuery) ||
              address.contains(normalizedQuery);
        })
        .toList(growable: true);

    results.sort((Station a, Station b) {
      final bool aHasAvailability = hasAvailabilityForCurrentMode(a);
      final bool bHasAvailability = hasAvailabilityForCurrentMode(b);
      if (aHasAvailability != bHasAvailability) {
        return aHasAvailability ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return results.toList(growable: false);
  }

  Station? _findStationById(String id) {
    for (final Station station in _stations) {
      if (station.id == id) {
        return station;
      }
    }
    return null;
  }

  Station? _findNearestStation({
    required Station selected,
    required bool Function(Station station) isCandidate,
  }) {
    Station? nearestStation;
    double? nearestDistance;

    for (final Station station in _stations) {
      if (station.id == selected.id || !isCandidate(station)) {
        continue;
      }

      final double distance = _distanceSquared(selected, station);
      if (nearestStation == null || distance < nearestDistance!) {
        nearestStation = station;
        nearestDistance = distance;
      }
    }

    return nearestStation;
  }

  double _distanceSquared(Station a, Station b) {
    final double latDiff = a.latitude - b.latitude;
    final double lngDiff = a.longitude - b.longitude;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }

  void _applyRideState({required bool isActive}) {
    _hasActiveRide = isActive;
    _selectedStation = null;
    _isReturnBannerVisible = isActive;
    _activeRoutePath = <GeoCoordinate>[];
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

class _UnavailableUserLocationRepository implements UserLocationRepository {
  const _UnavailableUserLocationRepository();

  @override
  Future<UserLocationResult> getCurrentLocation() async {
    return const UserLocationResult(status: UserLocationStatus.unavailable);
  }
}

class _UnavailableNavigationLauncherRepository
    implements NavigationLauncherRepository {
  const _UnavailableNavigationLauncherRepository();

  @override
  Future<bool> openDirections({
    GeoCoordinate? origin,
    required GeoCoordinate destination,
  }) async {
    return false;
  }
}

class _EmptyStationRouteRepository implements StationRouteRepository {
  const _EmptyStationRouteRepository();

  @override
  Future<List<GeoCoordinate>> fetchCyclingRoute({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  }) async {
    return const <GeoCoordinate>[];
  }
}
