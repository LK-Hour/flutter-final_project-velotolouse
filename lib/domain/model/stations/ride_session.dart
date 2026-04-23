/// Represents an active or completed ride session.
class RideSession {
  const RideSession({
    required this.id,
    required this.bikeCode,
    required this.stationId,
    required this.startedAt,
    this.endedAt,
  });

  /// Unique session identifier.
  final String id;

  /// The code of the bike being ridden.
  final String bikeCode;

  /// The station from which the bike was taken.
  final String stationId;

  /// When the ride started.
  final DateTime startedAt;

  /// When the ride ended; null while still active.
  final DateTime? endedAt;

  bool get isActive => endedAt == null;

  Duration get elapsed {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  RideSession copyWith({
    String? id,
    String? bikeCode,
    String? stationId,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return RideSession(
      id: id ?? this.id,
      bikeCode: bikeCode ?? this.bikeCode,
      stationId: stationId ?? this.stationId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  String toString() =>
      'RideSession(id: $id, bike: $bikeCode, active: $isActive)';
}
