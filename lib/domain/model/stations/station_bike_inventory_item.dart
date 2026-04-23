import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';

class StationBikeInventoryItem {
  const StationBikeInventoryItem({
    required this.stationId,
    required this.slotId,
    required this.status,
    required this.bikeCode,
  });

  final String stationId;
  final String slotId;
  final BikeSlotStatus status;
  final String? bikeCode;

  bool get isAvailable => status == BikeSlotStatus.available;

  BikeSlot get bikeSlot {
    return BikeSlot(id: slotId, status: status, bikeCode: bikeCode);
  }
}
