class RidePaymentSummary {
  const RidePaymentSummary({
    required this.rideCostUsd,
    required this.rideCostKhr,
    required this.duration,
    required this.distanceKm,
  });

  final double rideCostUsd;
  final int rideCostKhr;
  final String duration;
  final double distanceKm;
}
