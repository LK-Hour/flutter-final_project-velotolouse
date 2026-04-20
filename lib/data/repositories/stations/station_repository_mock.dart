import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';

class MockStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const <Station>[
      Station(
        id: 'wat-phnom',
        name: 'Wat Phnom',
        address: 'Street 94, Daun Penh, Phnom Penh',
        availableBikes: 3,
        totalCapacity: 12,
        latitude: 11.559729,
        longitude: 104.910392,
      ),
      Station(
        id: 'central-market',
        name: 'Central Market',
        address: 'Phnom, Samdach Sang Neayok Srey St. (67), Penh 12209',
        availableBikes: 5,
        totalCapacity: 5,
        latitude: 11.569599,
        longitude: 104.920129,
      ),
      Station(
        id: 'independence-monument',
        name: 'Independence Monument',
        address: 'Preah Sihanouk Blvd, Chamkar Mon, Phnom Penh',
        availableBikes: 8,
        totalCapacity: 16,
        latitude: 11.556374,
        longitude: 104.927551,
      ),
    ];
  }
}
