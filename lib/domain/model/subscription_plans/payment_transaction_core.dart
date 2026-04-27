class PaymentTransactionCore {
  const PaymentTransactionCore({
    required this.id,
    required this.bankName,
    required this.bankShortName,
    required this.amountUsd,
    required this.createdAt,
  });

  final String id;
  final String bankName;
  final String bankShortName;
  final double amountUsd;
  final DateTime? createdAt;
}