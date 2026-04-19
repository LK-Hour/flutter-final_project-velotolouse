import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/instant_payment_data.dart';
import '../../../domain/model/subscription_plans/ride_payment_summary.dart';
import '../../../domain/repositories/subscription_plans/instant_payment_repository.dart';

class MockInstantPaymentRepository implements InstantPaymentRepository {
  @override
  Future<InstantPaymentData> fetchInstantPaymentData() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return const InstantPaymentData(
      summary: RidePaymentSummary(
        rideCostUsd: 1.50,
        rideCostKhr: 6150,
        duration: '14:02',
        distanceKm: 2.4,
      ),
      banks: [
        BankOption(
          id: 'aba',
          shortName: 'ABA',
          name: 'ABA Bank',
          subtitle: 'KHQR · Mobile Banking',
          colorHex: 0xFF1E3E93,
        ),
        BankOption(
          id: 'wing',
          shortName: 'WING',
          name: 'Wing Bank',
          subtitle: 'Wing Money App',
          colorHex: 0xFFB31318,
        ),
        BankOption(
          id: 'acleda',
          shortName: 'ACLEDA',
          name: 'ACLEDA Bank',
          subtitle: 'Unity ToanChet',
          colorHex: 0xFF0A5FA8,
        ),
        BankOption(
          id: 'nbc',
          shortName: 'NBC',
          name: 'Bakong · NBC',
          subtitle: 'National KHQR',
          colorHex: 0xFFBE2027,
        ),
      ],
    );
  }
}
