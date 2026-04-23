import 'package:final_project_velotolouse/data/firebase/firebase_rtdb_client.dart';
import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';
import 'package:final_project_velotolouse/domain/model/stations/station_bike_inventory_item.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/station_bike_inventory_repository.dart';

class FirebaseStationBikeInventoryRepository
    implements StationBikeInventoryRepository {
  FirebaseStationBikeInventoryRepository({FirebaseRtdbClient? client})
    : _client = client ?? FirebaseRtdbClient();

  final FirebaseRtdbClient _client;

  @override
  Future<List<StationBikeInventoryItem>> fetchBikesForStation(
    String stationId,
  ) async {
    final Map<String, dynamic>? data = await _client.getObject('bikeInventory');
    if (data == null || data.isEmpty) {
      return const <StationBikeInventoryItem>[];
    }

    final List<StationBikeInventoryItem> items = <StationBikeInventoryItem>[];
    for (final MapEntry<String, dynamic> entry in data.entries) {
      final Object? rawRecord = entry.value;
      if (rawRecord is! Map<String, dynamic>) {
        continue;
      }

      final StationBikeInventoryItem? item = _parseItem(entry.key, rawRecord);
      if (item != null && item.stationId == stationId) {
        items.add(item);
      }
    }

    items.sort((left, right) {
      if (left.isAvailable != right.isAvailable) {
        return left.isAvailable ? -1 : 1;
      }
      return left.slotId.compareTo(right.slotId);
    });

    return items;
  }

  StationBikeInventoryItem? _parseItem(
    String fallbackCode,
    Map<String, dynamic> json,
  ) {
    final String stationId = json['stationId'] as String? ?? '';
    if (stationId.isEmpty) {
      return null;
    }

    final String statusValue = (json['status'] as String? ?? 'unavailable')
        .toLowerCase();
    final BikeSlotStatus status = statusValue == 'available'
        ? BikeSlotStatus.available
        : BikeSlotStatus.unavailable;

    return StationBikeInventoryItem(
      stationId: stationId,
      slotId: json['slotId'] as String? ?? fallbackCode,
      status: status,
      bikeCode: json['bikeCode'] as String?,
    );
  }
}
