import 'package:cloud_firestore/cloud_firestore.dart';

import '../../dto/subscription_plans/bank_option_dto.dart';
import '../../dto/subscription_plans/instant_payment_data_dto.dart';
import '../../dto/subscription_plans/instant_payment_transaction_dto.dart';
import '../../dto/subscription_plans/ride_payment_summary_dto.dart';
import '../../dto/subscription_plans/subscription_transaction_dto.dart';
import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/instant_payment_data.dart';
import '../../../domain/model/subscription_plans/instant_payment_transaction.dart';
import '../../../domain/model/subscription_plans/ride_payment_summary.dart';
import '../../../domain/model/subscription_plans/subscription_transaction.dart';
import '../../../domain/repositories/subscription_plans/instant_payment_repository.dart';
import '../../../ui/screens/subscription_plans/state/subscription_refresh_notifier.dart';

class FirestoreInstantPaymentRepository implements InstantPaymentRepository {
  FirestoreInstantPaymentRepository({
    FirebaseFirestore? firestore,
    SubscriptionRefreshNotifier? refreshNotifier,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _refreshNotifier = refreshNotifier;

  final FirebaseFirestore _firestore;
  final SubscriptionRefreshNotifier? _refreshNotifier;

  @override
  Future<InstantPaymentData> fetchInstantPaymentData() async {
    final summaryDoc = await _firestore
        .collection('app_config')
        .doc('instant_payment')
        .get();

    final summaryDto = RidePaymentSummaryDto.fromFirestore(summaryDoc.data());

    final banksSnapshot = await _firestore
        .collection('app_config')
        .doc('instant_payment')
        .collection('bank_options')
        .orderBy('order', descending: false)
        .get();

    final bankDtos = banksSnapshot.docs
        .map((doc) => BankOptionDto.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);

    return InstantPaymentDataDto(
      summary: summaryDto,
      banks: bankDtos,
    ).toDomain(fallbackBanks: _defaultBanks);
  }

  @override
  Future<void> createInstantPaymentTransaction({
    required RidePaymentSummary summary,
    required BankOption bank,
  }) async {
    final dto = InstantPaymentTransactionDto.fromDomain(
      summary: summary,
      bank: bank,
    );

    await _firestore
        .collection('instant_payment_transactions')
        .add(dto.toFirestoreMap());
  }

  @override
  Future<void> createSubscriptionTransaction({
    required String planId,
    required String planLabel,
    required double amountUsd,
    required BankOption bank,
  }) async {
    final dto = SubscriptionTransactionDto.fromDomain(
      planId: planId,
      planLabel: planLabel,
      amountUsd: amountUsd,
      bank: bank,
    );

    await _firestore
        .collection('subscription_transactions')
        .add(dto.toFirestoreMap());
    _refreshNotifier?.markUpdated();
  }

  @override
  Future<List<InstantPaymentTransaction>>
  fetchInstantPaymentTransactions() async {
    final snapshot = await _firestore
        .collection('instant_payment_transactions')
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map(
          (doc) => InstantPaymentTransactionDto.fromFirestore(
            doc.id,
            doc.data(),
          ).toDomain(),
        )
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
        .map(
          (doc) => SubscriptionTransactionDto.fromFirestore(
            doc.id,
            doc.data(),
          ).toDomain(),
        )
        .toList(growable: false);
  }

  @override
  Future<void> cancelSubscriptionTransaction(String transactionId) async {
    await _firestore
        .collection('subscription_transactions')
        .doc(transactionId)
        .delete();
    _refreshNotifier?.markUpdated();
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
