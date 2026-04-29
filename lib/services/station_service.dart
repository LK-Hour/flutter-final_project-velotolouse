import 'package:final_project_velotolouse/domain/model/stations/station.dart';

/// Service layer for station-related business logic.
/// 
/// Handles:
/// - Station filtering and searching
/// - Distance calculations
/// - Availability checks for different modes (rent/return)
/// - Finding nearest stations
class StationService {
  /// Filters stations by search query (name or address).
  /// 
  /// If [isReturnMode] 
  List<Station> searchStations(
    List<Station> stations,
    String query, {
    required bool isReturnMode,
  }) {
    final String normalizedQuery = query.trim().toLowerCase();
    final List<Station> results = stations
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

    if (isReturnMode) {
      results.sort((Station a, Station b) {
        final bool aHasAvailability = a.freeDocks > 0;
        final bool bHasAvailability = b.freeDocks > 0;
        if (aHasAvailability != bHasAvailability) {
          return aHasAvailability ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
    }

    return results.toList(growable: false);
  }

  /// Checks if a station has availability for the current mode.
  /// 
  /// - Return mode: checks for free docks
  /// - Rent mode: checks for available bikes
  bool hasAvailability(Station station, {required bool isReturnMode}) {
    return isReturnMode ? station.freeDocks > 0 : station.availableBikes > 0;
  }

  /// Returns a user-friendly availability label for the current mode.
  String getAvailabilityLabel(Station station, {required bool isReturnMode}) {
    return isReturnMode
        ? '${station.freeDocks} Docks'
        : '${station.availableBikes} Bikes';
  }

  /// Finds the nearest station to [targetStation] that has free docks.
  /// 
  /// Returns null if no suitable alternative is found.
  Station? findNearestStationWithDocks(
    Station targetStation,
    List<Station> allStations,
  ) {
    Station? nearestStation;
    double? nearestDistance;

    for (final Station station in allStations) {
      if (station.id == targetStation.id || station.freeDocks <= 0) {
        continue;
      }

      final double distance = _distanceSquared(targetStation, station);
      if (nearestStation == null || distance < nearestDistance!) {
        nearestStation = station;
        nearestDistance = distance;
      }
    }

    return nearestStation;
  }

  /// Calculates squared distance between two stations (avoids sqrt for performance).
  double _distanceSquared(Station a, Station b) {
    final double latDiff = a.latitude - b.latitude;
    final double lonDiff = a.longitude - b.longitude;
    return latDiff * latDiff + lonDiff * lonDiff;
  }

  /// Finds a station by its ID from a list.
  Station? findStationById(List<Station> stations, String id) {
    for (final Station station in stations) {
      if (station.id == id) {
        return station;
      }
    }
    return null;
  }

  /// Updates station availability after returning a bike.
  /// 
  /// Returns a new list with the updated station.
  List<Station> updateStationAfterReturn(
    List<Station> stations,
    String stationId,
  ) {
    return stations
        .map((Station station) {
          if (station.id != stationId) {
            return station;
          }
          return station.copyWith(
            availableBikes: station.availableBikes + 1,
          );
        })
        .toList(growable: false);
  }
}
