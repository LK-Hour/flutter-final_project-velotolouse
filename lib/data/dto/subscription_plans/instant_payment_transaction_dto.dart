import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/instant_payment_transaction.dart';
import '../../../domain/model/subscription_plans/ride_payment_summary.dart';

class InstantPaymentTransactionDto {
  const InstantPaymentTransactionDto({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.bankShortName,
    required this.amountUsd,
    required this.amountKhr,
    required this.duration,
    required this.distanceKm,
    this.createdAt,
  });

  final String id;
  final String bankId;
  final String bankName;
  final String bankShortName;
  final double amountUsd;
  final int amountKhr;
  final String duration;
  final double distanceKm;
  final DateTime? createdAt;

  factory InstantPaymentTransactionDto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['created_at'];
    DateTime? createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }

    return InstantPaymentTransactionDto(
      id: id,
      bankId: (data['bank_id'] as String?) ?? 'unknown',
      bankName: (data['bank_name'] as String?) ?? 'Unknown Bank',
      bankShortName: (data['bank_short_name'] as String?) ?? 'BANK',
      amountUsd: _asDouble(data['amount_usd'], fallback: 0),
      amountKhr: _asInt(data['amount_khr'], fallback: 0),
      duration: (data['duration'] as String?) ?? '-',
      distanceKm: _asDouble(data['distance_km'], fallback: 0),
      createdAt: createdAt,
    );
  }

  factory InstantPaymentTransactionDto.fromDomain({
    required RidePaymentSummary summary,
    required BankOption bank,
  }) {
    return InstantPaymentTransactionDto(
      id: '',
      bankId: bank.id,
      bankName: bank.name,
      bankShortName: bank.shortName,
      amountUsd: summary.rideCostUsd,
      amountKhr: summary.rideCostKhr,
      duration: summary.duration,
      distanceKm: summary.distanceKm,
    );
  }

  Map<String, Object?> toFirestoreMap() {
    return {
      'bank_id': bankId,
      'bank_name': bankName,
      'bank_short_name': bankShortName,
      'amount_usd': amountUsd,
      'amount_khr': amountKhr,
      'duration': duration,
      'distance_km': distanceKm,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  InstantPaymentTransaction toDomain() {
    return InstantPaymentTransaction(
      id: id,
      bankName: bankName,
      bankShortName: bankShortName,
      amountUsd: amountUsd,
      amountKhr: amountKhr,
      duration: duration,
      distanceKm: distanceKm,
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
}
