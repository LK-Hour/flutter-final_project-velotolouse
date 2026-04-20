import '../../model/subscription_plans/instant_payment_data.dart';

abstract class InstantPaymentRepository {
  Future<InstantPaymentData> fetchInstantPaymentData();
}