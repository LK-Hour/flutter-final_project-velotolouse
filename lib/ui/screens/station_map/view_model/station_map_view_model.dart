import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:flutter/foundation.dart';

class StationMapViewModel extends ChangeNotifier {
  StationMapViewModel({required StationRepository repository})
    : _repository = repository;

  final StationRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Station> _stations = <Station>[];
  Station? _selectedStation;
  bool _hasActiveRide = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Station> get stations => List<Station>.unmodifiable(_stations);
  Station? get selectedStation => _selectedStation;
  bool get hasActiveRide => _hasActiveRide;
  bool get isReturnMode => _hasActiveRide;
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

    return _stations.where((Station station) {
      final String name = station.name.toLowerCase();
      final String address = station.address.toLowerCase();
      return name.contains(normalizedQuery) || address.contains(normalizedQuery);
    }).toList(growable: false);
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
