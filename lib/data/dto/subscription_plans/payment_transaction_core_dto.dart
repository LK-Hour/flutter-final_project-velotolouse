import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/subscription_plans/payment_transaction_core.dart';

class PaymentTransactionCoreDto {
  const PaymentTransactionCoreDto._();

  static PaymentTransactionCore fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['created_at'];
    DateTime? createdAt;
    if (timestamp is Timestamp) createdAt = timestamp.toDate();

    return PaymentTransactionCore(
      id: id,
      bankName: (data['bank_name'] as String?) ?? '',
      bankShortName: (data['bank_short_name'] as String?) ?? '',
      amountUsd: _asDouble(data['amount_usd'], fallback: 0),
      createdAt: createdAt,
    );
  }

  static PaymentTransactionCore fromFields({
    required String id,
    required String bankName,
    required String bankShortName,
    required double amountUsd,
    DateTime? createdAt,
  }) {
    return PaymentTransactionCore(
      id: id,
      bankName: bankName,
      bankShortName: bankShortName,
      amountUsd: amountUsd,
      createdAt: createdAt,
    );
  }

  static Map<String, Object?> toFirestoreMap({
    required String bankId,
    required String bankName,
    required String bankShortName,
    required double amountUsd,
  }) {
    return {
      'bank_id': bankId,
      'bank_name': bankName,
      'bank_short_name': bankShortName,
      'amount_usd': amountUsd,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  static double _asDouble(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return fallback;
  }
}
