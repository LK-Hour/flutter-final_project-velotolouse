import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/instant_payment_data.dart';
import '../../../domain/model/subscription_plans/instant_payment_transaction.dart';
import '../../../domain/model/subscription_plans/ride_payment_summary.dart';
import '../../../domain/model/subscription_plans/subscription_transaction.dart';
import '../../../domain/repositories/subscription_plans/instant_payment_repository.dart';

class FirestoreInstantPaymentRepository implements InstantPaymentRepository {
  FirestoreInstantPaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<InstantPaymentData> fetchInstantPaymentData() async {
    final summaryDoc =
        await _firestore.collection('app_config').doc('instant_payment').get();

    final summaryData = summaryDoc.data();
    final summary = RidePaymentSummary(
      rideCostUsd: _asDouble(summaryData?['ride_cost_usd'], fallback: 1.50),
      rideCostKhr: _asInt(summaryData?['ride_cost_khr'], fallback: 6150),
      duration: (summaryData?['duration'] as String?) ?? '14:02',
      distanceKm: _asDouble(summaryData?['distance_km'], fallback: 2.4),
    );

    final banksSnapshot = await _firestore
        .collection('app_config')
        .doc('instant_payment')
        .collection('bank_options')
        .orderBy('order', descending: false)
        .get();

    final banks = banksSnapshot.docs
        .map((doc) => _bankFromMap(doc.id, doc.data()))
        .toList(growable: false);

    return InstantPaymentData(
      summary: summary,
      banks: banks.isEmpty ? _defaultBanks : banks,
    );
  }

  @override
  Future<void> createInstantPaymentTransaction({
    required RidePaymentSummary summary,
    required BankOption bank,
  }) async {
    await _firestore.collection('instant_payment_transactions').add({
      'bank_id': bank.id,
      'bank_name': bank.name,
      'bank_short_name': bank.shortName,
      'amount_usd': summary.rideCostUsd,
      'amount_khr': summary.rideCostKhr,
      'duration': summary.duration,
      'distance_km': summary.distanceKm,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createSubscriptionTransaction({
    required String planId,
    required String planLabel,
    required double amountUsd,
    required BankOption bank,
  }) async {
    await _firestore.collection('subscription_transactions').add({
      'plan_id': planId,
      'plan_label': planLabel,
      'bank_id': bank.id,
      'bank_name': bank.name,
      'bank_short_name': bank.shortName,
      'amount_usd': amountUsd,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<InstantPaymentTransaction>> fetchInstantPaymentTransactions() async {
    final snapshot = await _firestore
        .collection('instant_payment_transactions')
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => _transactionFromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<List<SubscriptionTransaction>> fetchSubscriptionTransactions() async {
    final snapshot = await _firestore
        .collection('subscription_transactions')
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => _subscriptionTransactionFromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  BankOption _bankFromMap(String id, Map<String, dynamic> data) {
    return BankOption(
      id: id,
      shortName: (data['short_name'] as String?) ?? id.toUpperCase(),
      name: (data['name'] as String?) ?? 'Unknown Bank',
      subtitle: (data['subtitle'] as String?) ?? '',
      colorHex: _asInt(data['color_hex'], fallback: 0xFF1E3E93),
    );
  }

  InstantPaymentTransaction _transactionFromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['created_at'];
    DateTime? createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }

    return InstantPaymentTransaction(
      id: id,
      bankName: (data['bank_name'] as String?) ?? 'Unknown Bank',
      bankShortName: (data['bank_short_name'] as String?) ?? 'BANK',
      amountUsd: _asDouble(data['amount_usd'], fallback: 0),
      amountKhr: _asInt(data['amount_khr'], fallback: 0),
      duration: (data['duration'] as String?) ?? '-',
      distanceKm: _asDouble(data['distance_km'], fallback: 0),
      createdAt: createdAt,
    );
  }

  SubscriptionTransaction _subscriptionTransactionFromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['created_at'];
    DateTime? createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }

    return SubscriptionTransaction(
      id: id,
      planId: (data['plan_id'] as String?) ?? 'unknown',
      planLabel: (data['plan_label'] as String?) ?? 'Subscription',
      bankName: (data['bank_name'] as String?) ?? 'Unknown Bank',
      bankShortName: (data['bank_short_name'] as String?) ?? 'BANK',
      amountUsd: _asDouble(data['amount_usd'], fallback: 0),
      createdAt: createdAt,
    );
  }

  static double _asDouble(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static const List<BankOption> _defaultBanks = [
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
  ];
}
