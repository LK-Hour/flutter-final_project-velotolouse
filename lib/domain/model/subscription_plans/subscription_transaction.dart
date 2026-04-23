class SubscriptionTransaction {
  const SubscriptionTransaction({
    required this.id,
    required this.planId,
    required this.planLabel,
    required this.bankName,
    required this.bankShortName,
    required this.amountUsd,
    required this.createdAt,
    this.status = 'active',
  });

  final String id;
  final String planId;
  final String planLabel;
  final String bankName;
  final String bankShortName;
  final double amountUsd;
  final DateTime? createdAt;
  final String status;
}