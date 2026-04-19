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
}
