import '../../../domain/model/subscription_plans/ride_payment_summary.dart';

class RidePaymentSummaryDto {
  const RidePaymentSummaryDto({
    required this.rideCostUsd,
    required this.rideCostKhr,
    required this.duration,
    required this.distanceKm,
  });

  final double rideCostUsd;
  final int rideCostKhr;
  final String duration;
  final double distanceKm;

  factory RidePaymentSummaryDto.fromFirestore(Map<String, dynamic>? data) {
    return RidePaymentSummaryDto(
      rideCostUsd: _asDouble(data?['ride_cost_usd'], fallback: 1.50),
      rideCostKhr: _asInt(data?['ride_cost_khr'], fallback: 6150),
      duration: (data?['duration'] as String?) ?? '14:02',
      distanceKm: _asDouble(data?['distance_km'], fallback: 2.4),
    );
  }

  RidePaymentSummary toDomain() {
    return RidePaymentSummary(
      rideCostUsd: rideCostUsd,
      rideCostKhr: rideCostKhr,
      duration: duration,
      distanceKm: distanceKm,
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
