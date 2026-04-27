import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/payment_transaction_core.dart';
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
    this.userId = 'Ronan The Best',
    this.createdAt,
    this.status = 'active',
  });

  final String id;
  final String planId;
  final String planLabel;
  final String bankId;
  final String bankName;
  final String bankShortName;
  final double amountUsd;
  final String userId;
  final DateTime? createdAt;
  final String status;

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
      userId: (data['user_id'] as String?) ?? 'Ronan The Best',
      createdAt: createdAt,
      status: (data['status'] as String?) ?? 'active',
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
      userId: 'Ronan The Best',
      status: 'active',
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
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  SubscriptionTransaction toDomain() {
    final core = PaymentTransactionCore(
      id: id,
      bankName: bankName,
      bankShortName: bankShortName,
      amountUsd: amountUsd,
      createdAt: createdAt,
      status: status,
    );

    return SubscriptionTransaction(
      core: core,
      planId: planId,
      planLabel: planLabel,
    );
  }

  static double _asDouble(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }
}
