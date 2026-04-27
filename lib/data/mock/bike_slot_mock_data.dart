import 'package:final_project_velotolouse/domain/model/stations/bike_slot.dart';

/// Mock list of 10 BikeSlot objects for Capitole Square station.
/// Status is computed from bike presence: 3 bikes available out of 10 slots.
const List<BikeSlot> mockCapitoleSlots = <BikeSlot>[
  BikeSlot(id: 'CO-01', stationId: 'capitole-square', bikeCode: 'CO-04'),
  BikeSlot(id: 'CO-02', stationId: 'capitole-square'),
  BikeSlot(id: 'CO-03', stationId: 'capitole-square'),
  BikeSlot(id: 'CO-04', stationId: 'capitole-square', bikeCode: 'CO-07'),
  BikeSlot(id: 'CO-05', stationId: 'capitole-square'),
  BikeSlot(id: 'CO-06', stationId: 'capitole-square'),
  BikeSlot(id: 'CO-07', stationId: 'capitole-square', bikeCode: 'CO-11'),
  BikeSlot(id: 'CO-08', stationId: 'capitole-square'),
  BikeSlot(id: 'CO-09', stationId: 'capitole-square'),
  BikeSlot(id: 'CO-10', stationId: 'capitole-square'),
];

/// Returns the mock slots for a given station id.
/// Falls back to an empty list for stations without mock slot data.
List<BikeSlot> mockSlotsForStation(String stationId) {
  return switch (stationId) {
    'capitole-square' => mockCapitoleSlots,
    _ => const <BikeSlot>[],
  };
}
