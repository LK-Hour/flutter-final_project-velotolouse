import 'payment_transaction_core.dart';

class SubscriptionTransaction {
  const SubscriptionTransaction({
    required this.core,
    required this.planId,
    required this.planLabel,
    this.status = 'active',
  });

  final PaymentTransactionCore core;
  final String planId;
  final String planLabel;
  final String status;
}