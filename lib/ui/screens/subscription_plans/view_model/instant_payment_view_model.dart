import 'package:flutter/foundation.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';
import '../../../../domain/model/subscription_plans/ride_payment_summary.dart';
import '../../../../domain/repositories/subscription_plans/instant_payment_repository.dart';

class InstantPaymentViewModel extends ChangeNotifier {
  InstantPaymentViewModel({required InstantPaymentRepository repository})
      : _repository = repository;

  final InstantPaymentRepository _repository;

  RidePaymentSummary? _summary;
  List<BankOption> _banks = const [];
  int _selectedBankIndex = 0;
  bool _isLoading = false;
  bool _isPaying = false;
  String? _errorMessage;

  RidePaymentSummary? get summary => _summary;
  List<BankOption> get banks => _banks;
  int get selectedBankIndex => _selectedBankIndex;
  bool get isLoading => _isLoading;
  bool get isPaying => _isPaying;
  String? get errorMessage => _errorMessage;

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
      _summary = data.summary;
      _banks = data.banks;
      _selectedBankIndex = 0;
    } catch (_) {
      _errorMessage = 'Failed to load payment options.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectBank(int index) {
    if (index < 0 || index >= _banks.length || index == _selectedBankIndex) {
      return;
    }

    _selectedBankIndex = index;
    notifyListeners();
  }

  Future<bool> payNow() async {
    if (_isPaying || selectedBank == null || _summary == null) {
      return false;
    }

    _isPaying = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 800));

    _isPaying = false;
    notifyListeners();
    return true;
  }
}
