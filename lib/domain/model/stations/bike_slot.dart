/// Represents a single docking slot at a station.
/// 
/// Status is computed from bike presence: if [bikeCode] is not null, the slot
/// has a bike available; otherwise, the slot is empty.
class BikeSlot {
  const BikeSlot({
    required this.id,
    required this.stationId,
    this.bikeCode,
  });

  /// Unique slot identifier, e.g. "CO-01".
  final String id;

  /// The station this slot belongs to.
  final String stationId;

  /// The code of the bike currently docked, or null when empty.
  final String? bikeCode;

  /// Whether this slot has a bike available for rental.
  /// Computed from [bikeCode] presence.
  bool get isAvailable => bikeCode != null;

  /// Whether this slot is empty (no bike docked).
  /// Computed from [bikeCode] absence.
  bool get isEmpty => bikeCode == null;

  BikeSlot copyWith({
    String? id,
    String? stationId,
    String? bikeCode,
  }) {
    return BikeSlot(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      bikeCode: bikeCode,
    );
  }

  @override
  String toString() =>
      'BikeSlot(id: $id, stationId: $stationId, bikeCode: $bikeCode, isAvailable: $isAvailable)';
}
