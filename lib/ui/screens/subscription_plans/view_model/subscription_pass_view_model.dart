import 'package:flutter/foundation.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';
import '../../../../domain/model/subscription_plans/payment_transactions.dart';
import '../../../../domain/repositories/subscription_plans/instant_payment_repository.dart';

class SubscriptionPassViewModel extends ChangeNotifier {
  SubscriptionPassViewModel({required InstantPaymentRepository repository})
    : _repository = repository;

  final InstantPaymentRepository _repository;

  bool _isProcessing = false;
  String? _errorMessage;
  SubscriptionTransaction? _activeSubscription;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  SubscriptionTransaction? get activeSubscription => _activeSubscription;
  bool get hasActiveSubscription =>
      _activeSubscription != null && _activeSubscription!.status == 'active';

  Future<void> loadActiveSubscription() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactions = await _repository.fetchSubscriptionTransactions();
      final activeTransactions = transactions
          .where((tx) => tx.status == 'active')
          .toList();
      _activeSubscription = activeTransactions.isNotEmpty
          ? activeTransactions.first
          : null;
    } catch (_) {
      _errorMessage = 'Failed to load active subscriptions.';
    }

    _isProcessing = false;
    notifyListeners();
  }

  Future<bool> subscribe({
    required String planId,
    required String planLabel,
    required double amountUsd,
    required BankOption bank,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactions = await _repository.fetchSubscriptionTransactions();
      final activeTransactions = transactions
          .where((tx) => tx.status == 'active')
          .toList();

      if (activeTransactions.isNotEmpty) {
        _activeSubscription = activeTransactions.first;
        _isProcessing = false;
        _errorMessage = 'You already have an active subscription.';
        notifyListeners();
        return false;
      }

      await _repository.createSubscriptionTransaction(
        planId: planId,
        planLabel: planLabel,
        amountUsd: amountUsd,
        bank: bank,
      );

      await loadActiveSubscription();
      return true;
    } catch (_) {
      _isProcessing = false;
      _errorMessage = 'Failed to save subscription. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    if (!hasActiveSubscription) return false;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancelSubscriptionTransaction(_activeSubscription!.core.id);
      _activeSubscription = null;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isProcessing = false;
      _errorMessage = 'Failed to cancel subscription. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
