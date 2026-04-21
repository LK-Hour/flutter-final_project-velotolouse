import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/subscription_transaction.dart';

class SubscriptionTransactionDto {
  const SubscriptionTransactionDto({
    required this.id,
    required this.planId,
    required this.planLabel,
    required this.bankId,
    required this.bankName,
    required this.bankShortName,
    required this.amountUsd,
    this.createdAt,
  });

  final String id;
  final String planId;
  final String planLabel;
  final String bankId;
  final String bankName;
  final String bankShortName;
  final double amountUsd;
  final DateTime? createdAt;

  factory SubscriptionTransactionDto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['created_at'];
    DateTime? createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }

    return SubscriptionTransactionDto(
      id: id,
      planId: (data['plan_id'] as String?) ?? 'unknown',
      planLabel: (data['plan_label'] as String?) ?? 'Subscription',
      bankId: (data['bank_id'] as String?) ?? 'unknown',
      bankName: (data['bank_name'] as String?) ?? 'Unknown Bank',
      bankShortName: (data['bank_short_name'] as String?) ?? 'BANK',
      amountUsd: _asDouble(data['amount_usd'], fallback: 0),
      createdAt: createdAt,
    );
  }

  factory SubscriptionTransactionDto.fromDomain({
    required String planId,
    required String planLabel,
    required double amountUsd,
    required BankOption bank,
  }) {
    return SubscriptionTransactionDto(
      id: '',
      planId: planId,
      planLabel: planLabel,
      bankId: bank.id,
      bankName: bank.name,
      bankShortName: bank.shortName,
      amountUsd: amountUsd,
    );
  }

  Map<String, Object?> toFirestoreMap() {
    return {
      'plan_id': planId,
      'plan_label': planLabel,
      'bank_id': bankId,
      'bank_name': bankName,
      'bank_short_name': bankShortName,
      'amount_usd': amountUsd,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  SubscriptionTransaction toDomain() {
    return SubscriptionTransaction(
      id: id,
      planId: planId,
      planLabel: planLabel,
      bankName: bankName,
      bankShortName: bankShortName,
      amountUsd: amountUsd,
      createdAt: createdAt,
    );
  }

  static double _asDouble(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }
}
