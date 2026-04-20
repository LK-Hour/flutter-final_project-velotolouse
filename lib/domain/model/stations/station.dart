class Station {
  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.availableBikes,
    required this.totalCapacity,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final int availableBikes;
  final int totalCapacity;
  final double latitude;
  final double longitude;

  bool get hasAvailableBikes => availableBikes > 0;
  int get freeDocks => totalCapacity - availableBikes;

  Station copyWith({
    String? id,
    String? name,
    String? address,
    int? availableBikes,
    int? totalCapacity,
    double? latitude,
    double? longitude,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      availableBikes: availableBikes ?? this.availableBikes,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
