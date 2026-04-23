import 'package:final_project_velotolouse/data/firebase/firebase_rtdb_client.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';

class FirebaseStationRepository implements StationRepository {
  FirebaseStationRepository({FirebaseRtdbClient? client})
    : _client = client ?? FirebaseRtdbClient();

  final FirebaseRtdbClient _client;

  @override
  Future<List<Station>> fetchStations() async {
    final Map<String, dynamic>? data = await _client.getObject('stations');
    if (data == null) {
      return const <Station>[];
    }

    final List<Station> stations = <Station>[];
    for (final MapEntry<String, dynamic> entry in data.entries) {
      final Object? rawStation = entry.value;
      if (rawStation is! Map<String, dynamic>) {
        continue;
      }
      stations.add(_stationFromJson(entry.key, rawStation));
    }
    return stations;
  }

  Station _stationFromJson(String id, Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String? ?? id,
      name: json['name'] as String? ?? id,
      address: json['address'] as String? ?? '',
      availableBikes: _asInt(json['availableBikes']),
      totalCapacity: _asInt(json['totalCapacity']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
