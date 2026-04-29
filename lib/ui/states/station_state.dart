import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:flutter/foundation.dart';

/// Global state for managing station data and map state.
/// 
/// Handles:
/// - Loading stations from repository
/// - Selected station
/// - Map center and user location
/// - Station availability updates
/// 
/// This is a global ChangeNotifier that can be listened to by multiple ViewModels.
class StationState extends ChangeNotifier {
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
  GeoCoordinate _mapCenter = defaultMapCenter;
  GeoCoordinate? _currentUserLocation;
  int _locateRequestVersion = 0;

  StationState({
    required StationRepository repository,
    required UserLocationRepository userLocationRepository,
  })  : _repository = repository,
        _userLocationRepository = userLocationRepository;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Station> get stations => List<Station>.unmodifiable(_stations);
  Station? get selectedStation => _selectedStation;
  GeoCoordinate get mapCenter => _mapCenter;
  GeoCoordinate? get currentUserLocation => _currentUserLocation;
  int get locateRequestVersion => _locateRequestVersion;

  /// Loads stations from repository.
  Future<void> loadStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stations = await _repository.fetchStations();
      
      // Refresh selected station if it was previously selected
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

  /// Selects a station by ID.
  void selectStation(String stationId) {
    final Station? station = _findStationById(stationId);
    if (station == null) {
      return;
    }
    _selectedStation = station;
    notifyListeners();
  }

  /// Clears the selected station.
  void clearSelectedStation() {
    if (_selectedStation == null) {
      return;
    }
    _selectedStation = null;
    notifyListeners();
  }

  /// Updates station availability after a bike return.
  /// 
  /// Increments the available bikes count for the station.
  void updateStationAfterReturn(String stationId) {
    _stations = _stations
        .map((Station station) {
          if (station.id != stationId) {
            return station;
          }
          return station.copyWith(
            availableBikes: station.availableBikes + 1,
          );
        })
        .toList(growable: false);
    
    // Update selected station if it's the one being returned to
    if (_selectedStation?.id == stationId) {
      _selectedStation = _findStationById(stationId);
    }
    
    notifyListeners();
  }

  /// Locates the current user position and centers the map.
  Future<UserLocationStatus> locateCurrentUser() async {
    final UserLocationResult result =
        await _userLocationRepository.getCurrentLocation();
        
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

  /// Finds a station by ID in the stations list.
  Station? _findStationById(String id) {
    for (final Station station in _stations) {
      if (station.id == id) {
        return station;
      }
    }
    return null;
  }
}
