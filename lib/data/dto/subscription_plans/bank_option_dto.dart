import '../../../domain/model/subscription_plans/bank_option.dart';

class BankOptionDto {
  const BankOptionDto({
    required this.id,
    required this.shortName,
    required this.name,
    required this.subtitle,
    required this.colorHex,
  });

  final String id;
  final String shortName;
  final String name;
  final String subtitle;
  final int colorHex;

  factory BankOptionDto.fromFirestore(String id, Map<String, dynamic> data) {
    return BankOptionDto(
      id: id,
      shortName: (data['short_name'] as String?) ?? id.toUpperCase(),
      name: (data['name'] as String?) ?? 'Unknown Bank',
      subtitle: (data['subtitle'] as String?) ?? '',
      colorHex: _asInt(data['color_hex'], fallback: 0xFF1E3E93),
    );
  }

  BankOption toDomain() {
    return BankOption(
      id: id,
      shortName: shortName,
      name: name,
      subtitle: subtitle,
      colorHex: colorHex,
    );
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
