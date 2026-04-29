/// Status values a bike slot can hold.
enum BikeSlotStatus { available, unavailable }

/// Represents a single docking slot at a station.
class BikeSlot {
  const BikeSlot({required this.id, required this.status, this.bikeCode})
    : assert(
        status != BikeSlotStatus.available || bikeCode != null,
        'An available slot must have a bikeCode.',
      );

  /// Unique slot identifier, e.g. "CO-01".
  final String id;

  /// Whether the slot holds a bike or is unavailable.
  final BikeSlotStatus status;

  /// The code of the bike currently docked, or null when unavailable.
  final String? bikeCode;

  bool get isAvailable => status == BikeSlotStatus.available;

  BikeSlot copyWith({String? id, BikeSlotStatus? status, String? bikeCode}) {
    return BikeSlot(
      id: id ?? this.id,
      status: status ?? this.status,
      bikeCode: bikeCode ?? this.bikeCode,
    );
  }

  @override
  String toString() =>
      'BikeSlot(id: $id, status: ${status.name}, bikeCode: $bikeCode)';
}
