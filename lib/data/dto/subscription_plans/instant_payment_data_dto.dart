import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/instant_payment_data.dart';
import 'bank_option_dto.dart';
import 'ride_payment_summary_dto.dart';

class InstantPaymentDataDto {
  const InstantPaymentDataDto({
    required this.summary,
    required this.banks,
  });

  final RidePaymentSummaryDto summary;
  final List<BankOptionDto> banks;

  InstantPaymentData toDomain({required List<BankOption> fallbackBanks}) {
    final bankModels = banks.map((dto) => dto.toDomain()).toList(growable: false);

    return InstantPaymentData(
      summary: summary.toDomain(),
      banks: bankModels.isEmpty ? fallbackBanks : bankModels,
    );
  }
}
