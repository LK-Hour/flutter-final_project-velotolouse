import 'bank_option.dart';
import 'ride_payment_summary.dart';

class InstantPaymentData {
  const InstantPaymentData({
    required this.summary,
    required this.banks,
  });

  final RidePaymentSummary summary;
  final List<BankOption> banks;
}
