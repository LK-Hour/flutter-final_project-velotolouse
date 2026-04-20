import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';

/// Mock list of 10 BikeSlot objects for Capitole Square station.
/// Statuses reflect the station's 3 available bikes out of 10 slots.
const List<BikeSlot> mockCapitoleSlots = <BikeSlot>[
  BikeSlot(id: 'CO-01', status: BikeSlotStatus.available, bikeCode: 'CO-04'),
  BikeSlot(id: 'CO-02', status: BikeSlotStatus.empty),
  BikeSlot(id: 'CO-03', status: BikeSlotStatus.empty),
  BikeSlot(id: 'CO-04', status: BikeSlotStatus.available, bikeCode: 'CO-07'),
  BikeSlot(id: 'CO-05', status: BikeSlotStatus.empty),
  BikeSlot(id: 'CO-06', status: BikeSlotStatus.empty),
  BikeSlot(id: 'CO-07', status: BikeSlotStatus.available, bikeCode: 'CO-11'),
  BikeSlot(id: 'CO-08', status: BikeSlotStatus.empty),
  BikeSlot(id: 'CO-09', status: BikeSlotStatus.empty),
  BikeSlot(id: 'CO-10', status: BikeSlotStatus.empty),
];

/// Returns the mock slots for a given station id.
/// Falls back to an empty list for stations without mock slot data.
List<BikeSlot> mockSlotsForStation(String stationId) {
  return switch (stationId) {
    'capitole-square' => mockCapitoleSlots,
    _ => const <BikeSlot>[],
  };
}
