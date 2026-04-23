def replace_in_file(filepath, old, new):
    with open(filepath, 'r') as f:
        c = f.read()
    with open(filepath, 'w') as f:
        f.write(c.replace(old, new))

repo_interface = 'lib/domain/repositories/subscription_plans/instant_payment_repository.dart'
mock_repo = 'lib/data/repositories/subscription_plans/mock_instant_payment_repository.dart'
fs_repo = 'lib/data/repositories/subscription_plans/firestore_instant_payment_repository.dart'

# 1. Interface
replace_in_file(repo_interface, 
    "Future<List<SubscriptionTransaction>> fetchSubscriptionTransactions();",
    "Future<List<SubscriptionTransaction>> fetchSubscriptionTransactions();\n\n  Future<void> cancelSubscriptionTransaction(String transactionId);")

# 2. Mock
replace_in_file(mock_repo,
    "createdAt: DateTime.now(),\n      ),",
    "createdAt: DateTime.now(),\n        status: 'active',\n      ),")

mock_impl = """  }

  @override
  Future<void> cancelSubscriptionTransaction(String transactionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _subscriptionTransactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final previous = _subscriptionTransactions[index];
      _subscriptionTransactions[index] = SubscriptionTransaction(
        id: previous.id,
        planId: previous.planId,
        planLabel: previous.planLabel,
        bankName: previous.bankName,
        bankShortName: previous.bankShortName,
        amountUsd: previous.amountUsd,
        createdAt: previous.createdAt,
        status: 'cancelled',
      );
    }
  }
}"""
replace_in_file(mock_repo, "  }\n}", mock_impl)

# 3. Firestore
fs_impl = """  }

  @override
  Future<void> cancelSubscriptionTransaction(String transactionId) async {
    await _firestore
        .collection('subscription_transactions')
        .doc(transactionId)
        .update({'status': 'cancelled'});
  }

  static const List<BankOption>"""
replace_in_file(fs_repo, "  }\n\n  static const List<BankOption>", fs_impl)

