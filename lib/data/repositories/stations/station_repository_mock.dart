import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';

class MockStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const <Station>[
      Station(
        id: 'capitole-square',
        name: 'Capitole Square',
        address: 'Place du Capitole, 31000 Toulouse',
        availableBikes: 3,
        totalCapacity: 12,
        latitude: 43.6044,
        longitude: 1.4442,
      ),
      Station(
        id: 'jean-jaures',
        name: 'Jean Jaures',
        address: 'Jean Jaures, 31000 Toulouse',
        availableBikes: 5,
        totalCapacity: 5,
        latitude: 43.6061,
        longitude: 1.4492,
      ),
      Station(
        id: 'carmes',
        name: 'Carmes',
        address: 'Place des Carmes, 31000 Toulouse',
        availableBikes: 8,
        totalCapacity: 16,
        latitude: 43.5994,
        longitude: 1.4449,
      ),
    ];
  }
}
