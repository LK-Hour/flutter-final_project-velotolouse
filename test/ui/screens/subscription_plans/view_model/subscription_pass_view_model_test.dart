import 'package:flutter_test/flutter_test.dart';

import 'package:final_project_velotolouse/domain/model/subscription_plans/bank_option.dart';
import 'package:final_project_velotolouse/domain/model/subscription_plans/ride_payment_summary.dart';
import 'package:final_project_velotolouse/domain/model/subscription_plans/payment_transactions.dart';
import 'package:final_project_velotolouse/domain/model/subscription_plans/payment_transaction_core.dart';
import 'package:final_project_velotolouse/domain/repositories/subscription_plans/instant_payment_repository.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/view_model/subscription_pass_view_model.dart';

class _FakeRepository implements InstantPaymentRepository {
  final List<SubscriptionTransaction> _subscriptions = [];

  @override
  Future<void> createSubscriptionTransaction({
    required String planId,
    required String planLabel,
    required double amountUsd,
    required BankOption bank,
  }) async {
    _subscriptions.insert(
      0,
      SubscriptionTransaction(
        core: PaymentTransactionCore(
          id: 'tx_${_subscriptions.length + 1}',
          bankName: bank.name,
          bankShortName: bank.shortName,
          amountUsd: amountUsd,
          createdAt: DateTime.now(),
        ),
        planId: planId,
        planLabel: planLabel,
        status: 'active',
      ),
    );
  }

  @override
  Future<void> cancelSubscriptionTransaction(String transactionId) async {
    final index = _subscriptions.indexWhere((s) => s.core.id == transactionId);
    if (index != -1) {
      final current = _subscriptions[index];
      _subscriptions[index] = SubscriptionTransaction(
        core: PaymentTransactionCore(
          id: current.core.id,
          bankName: current.core.bankName,
          bankShortName: current.core.bankShortName,
          amountUsd: current.core.amountUsd,
          createdAt: current.core.createdAt,
        ),
        planId: current.planId,
        planLabel: current.planLabel,
        status: 'canceled',
      );
    }
  }

  @override
  Future<void> createInstantPaymentTransaction({
    required RidePaymentSummary summary,
    required BankOption bank,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SubscriptionTransaction>> fetchSubscriptionTransactions() async {
    return List<SubscriptionTransaction>.from(_subscriptions);
  }

  @override
  Future<Never> fetchInstantPaymentData() {
    throw UnimplementedError();
  }

  @override
  Future<Never> fetchInstantPaymentTransactions() {
    throw UnimplementedError();
  }
}

void main() {
  const aba = BankOption(
    id: 'aba',
    shortName: 'ABA',
    name: 'ABA Bank',
    subtitle: 'KHQR',
    colorHex: 0xFF1E3E93,
  );

  group('SubscriptionPassViewModel', () {
    test('subscribe succeeds when there is no active subscription', () async {
      final repository = _FakeRepository();
      final viewModel = SubscriptionPassViewModel(repository: repository);

      final success = await viewModel.subscribe(
        planId: 'daily',
        planLabel: 'Daily Pass',
        amountUsd: 1.99,
        bank: aba,
      );

      expect(success, isTrue);
      expect(viewModel.hasActiveSubscription, isTrue);
      expect(viewModel.activeSubscription?.planId, 'daily');
      expect(viewModel.errorMessage, isNull);
    });

    test(
      'subscribe fails when there is already an active subscription',
      () async {
        final repository = _FakeRepository();
        final viewModel = SubscriptionPassViewModel(repository: repository);

        final firstSuccess = await viewModel.subscribe(
          planId: 'monthly',
          planLabel: 'Monthly Pass',
          amountUsd: 14.99,
          bank: aba,
        );
        expect(firstSuccess, isTrue);

        final secondSuccess = await viewModel.subscribe(
          planId: 'daily',
          planLabel: 'Daily Pass',
          amountUsd: 1.99,
          bank: aba,
        );

        expect(secondSuccess, isFalse);
        expect(
          viewModel.errorMessage,
          'You already have an active subscription.',
        );
        expect(viewModel.activeSubscription?.planId, 'monthly');
      },
    );

    test('can subscribe again after cancellation', () async {
      final repository = _FakeRepository();
      final viewModel = SubscriptionPassViewModel(repository: repository);

      final firstSuccess = await viewModel.subscribe(
        planId: 'annual',
        planLabel: 'Annual Pass',
        amountUsd: 99,
        bank: aba,
      );
      expect(firstSuccess, isTrue);

      final canceled = await viewModel.cancelSubscription();
      expect(canceled, isTrue);
      expect(viewModel.hasActiveSubscription, isFalse);

      final secondSuccess = await viewModel.subscribe(
        planId: 'daily',
        planLabel: 'Daily Pass',
        amountUsd: 1.99,
        bank: aba,
      );

      expect(secondSuccess, isTrue);
      expect(viewModel.activeSubscription?.planId, 'daily');
    });
  });
}
