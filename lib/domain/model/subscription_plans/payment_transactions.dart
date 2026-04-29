import 'payment_transaction_core.dart';
import 'ride_transaction_details.dart';

/// Combined transaction models for subscription and instant payments.
///
/// This file consolidates `InstantPaymentTransaction` and
/// `SubscriptionTransaction` to avoid duplicated definitions.

class InstantPaymentTransaction {
  const InstantPaymentTransaction({
    required this.core,
    required this.rideDetails,
  });

  final PaymentTransactionCore core;
  final RideTransactionDetails rideDetails;
}

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
