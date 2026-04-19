import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:flutter/foundation.dart';

class StationMapViewModel extends ChangeNotifier {
  StationMapViewModel({
    required StationRepository repository,
    UserLocationRepository? userLocationRepository,
  }) : _repository = repository,
       _userLocationRepository =
           userLocationRepository ?? const _UnavailableUserLocationRepository();

  final StationRepository _repository;
  final UserLocationRepository _userLocationRepository;
  static const GeoCoordinate defaultMapCenter = GeoCoordinate(
    latitude: 43.6046,
    longitude: 1.4442,
  );

  bool _isLoading = false;
  String? _errorMessage;
  List<Station> _stations = <Station>[];
  Station? _selectedStation;
  bool _hasActiveRide = false;
  GeoCoordinate _mapCenter = defaultMapCenter;
  GeoCoordinate? _currentUserLocation;
  int _locateRequestVersion = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Station> get stations => List<Station>.unmodifiable(_stations);
  Station? get selectedStation => _selectedStation;
  bool get hasActiveRide => _hasActiveRide;
  bool get isReturnMode => _hasActiveRide;
  GeoCoordinate get mapCenter => _mapCenter;
  GeoCoordinate? get currentUserLocation => _currentUserLocation;
  int get locateRequestVersion => _locateRequestVersion;
  bool get showFullStationRerouteAlert {
    return isReturnMode &&
        _selectedStation != null &&
        _selectedStation!.freeDocks == 0;
  }

  Station? get suggestedAlternativeDockStation {
    if (!showFullStationRerouteAlert) {
      return null;
    }

    final Station selected = _selectedStation!;
    Station? nearestStation;
    double? nearestDistance;

    for (final Station station in _stations) {
      if (station.id == selected.id || station.freeDocks <= 0) {
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
    _hasActiveRide = value;
    _selectedStation = null;
    notifyListeners();
  }

  void toggleReturnModeForTesting() {
    _hasActiveRide = !_hasActiveRide;
    _selectedStation = null;
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
    if (normalizedQuery.isEmpty) {
      return stations;
    }

    return _stations
        .where((Station station) {
          final String name = station.name.toLowerCase();
          final String address = station.address.toLowerCase();
          return name.contains(normalizedQuery) ||
              address.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Station? _findStationById(String id) {
    for (final Station station in _stations) {
      if (station.id == id) {
        return station;
      }
    }
    return null;
  }

  double _distanceSquared(Station a, Station b) {
    final double latDiff = a.latitude - b.latitude;
    final double lngDiff = a.longitude - b.longitude;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }
}

class _UnavailableUserLocationRepository implements UserLocationRepository {
  const _UnavailableUserLocationRepository();

  @override
  Future<UserLocationResult> getCurrentLocation() async {
    return const UserLocationResult(status: UserLocationStatus.unavailable);
  }
}
