import '../../model/subscription_plans/bank_option.dart';
import '../../model/subscription_plans/instant_payment_data.dart';
import '../../model/subscription_plans/instant_payment_transaction.dart';
import '../../model/subscription_plans/ride_payment_summary.dart';
import '../../model/subscription_plans/subscription_transaction.dart';

abstract class InstantPaymentRepository {
  Future<InstantPaymentData> fetchInstantPaymentData();

  Future<void> createInstantPaymentTransaction({
    required RidePaymentSummary summary,
    required BankOption bank,
  });

  Future<void> createSubscriptionTransaction({
    required String planId,
    required String planLabel,
    required double amountUsd,
    required BankOption bank,
  });

  Future<List<InstantPaymentTransaction>> fetchInstantPaymentTransactions();

  Future<List<SubscriptionTransaction>> fetchSubscriptionTransactions();
}