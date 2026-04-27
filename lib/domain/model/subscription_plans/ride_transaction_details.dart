class RideTransactionDetails {
  const RideTransactionDetails({
    required this.amountKhr,
    required this.duration,
    required this.distanceKm,
  });

  final int amountKhr;
  final String duration;
  final double distanceKm;
}