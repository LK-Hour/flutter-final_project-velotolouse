class InstantPaymentTransaction {
  const InstantPaymentTransaction({
    required this.id,
    required this.bankName,
    required this.bankShortName,
    required this.amountUsd,
    required this.amountKhr,
    required this.duration,
    required this.distanceKm,
    required this.createdAt,
  });

  final String id;
  final String bankName;
  final String bankShortName;
  final double amountUsd;
  final int amountKhr;
  final String duration;
  final double distanceKm;
  final DateTime? createdAt;
}