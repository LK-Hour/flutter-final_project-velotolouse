import 'package:flutter/foundation.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';
import '../../../../domain/model/subscription_plans/ride_payment_summary.dart';
import '../../../../domain/repositories/subscription_plans/instant_payment_repository.dart';

class InstantPaymentViewModel extends ChangeNotifier {
  InstantPaymentViewModel({required InstantPaymentRepository repository})
    : _repository = repository;

  final InstantPaymentRepository _repository;

  RidePaymentSummary? _baseSummary;
  List<BankOption> _banks = const [];
  int _selectedBankIndex = 0;
  bool _isLoading = false;
  bool _isPaying = false;
  String? _errorMessage;
  double? _customAmountUsd;

  RidePaymentSummary? get summary => _buildEffectiveSummary();
  RidePaymentSummary? get baseSummary => _baseSummary;
  List<BankOption> get banks => _banks;
  int get selectedBankIndex => _selectedBankIndex;
  bool get isLoading => _isLoading;
  bool get isPaying => _isPaying;
  String? get errorMessage => _errorMessage;
  double? get customAmountUsd => _customAmountUsd;

  BankOption? get selectedBank {
    if (_banks.isEmpty || _selectedBankIndex >= _banks.length) {
      return null;
    }
    return _banks[_selectedBankIndex];
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchInstantPaymentData();
      _baseSummary = data.summary;
      _banks = data.banks;
      _selectedBankIndex = 0;
      _customAmountUsd = data.summary.rideCostUsd;
    } catch (_) {
      _errorMessage = 'Failed to load payment options.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCustomAmountUsd(double amountUsd) {
    if (_baseSummary == null || amountUsd <= 0) {
      return;
    }

    _customAmountUsd = amountUsd;
    notifyListeners();
  }

  void selectBank(int index) {
    if (index < 0 || index >= _banks.length || index == _selectedBankIndex) {
      return;
    }

    _selectedBankIndex = index;
    notifyListeners();
  }

  Future<bool> payNow() async {
    final paymentSummary = _buildEffectiveSummary();

    if (_isPaying || selectedBank == null || paymentSummary == null) {
      return false;
    }

    _isPaying = true;
    notifyListeners();

    try {
      await _repository.createInstantPaymentTransaction(
        summary: paymentSummary,
        bank: selectedBank!,
      );
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Payment failed. Please try again.';
      _isPaying = false;
      notifyListeners();
      return false;
    }

    _isPaying = false;
    notifyListeners();
    return true;
  }

  RidePaymentSummary? _buildEffectiveSummary() {
    final summary = _baseSummary;
    if (summary == null) {
      return null;
    }

    final amountUsd = _customAmountUsd ?? summary.rideCostUsd;
    final rate = summary.rideCostUsd == 0
        ? 0
        : summary.rideCostKhr / summary.rideCostUsd;

    return RidePaymentSummary(
      rideCostUsd: amountUsd,
      rideCostKhr: (amountUsd * rate).round(),
      duration: summary.duration,
      distanceKm: summary.distanceKm,
    );
  }
}
