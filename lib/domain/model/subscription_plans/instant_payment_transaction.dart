import 'payment_transaction_core.dart';
import 'ride_transaction_details.dart';

class InstantPaymentTransaction {
  const InstantPaymentTransaction({
    required this.core,
    required this.rideDetails,
  });

  final PaymentTransactionCore core;
  final RideTransactionDetails rideDetails;
}