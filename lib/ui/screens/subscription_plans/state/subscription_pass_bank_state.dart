import 'package:flutter/foundation.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';

const List<BankOption> subscriptionPassBanks = [
  BankOption(
    id: 'aba',
    shortName: 'ABA',
    name: 'ABA Bank',
    subtitle: 'KHQR - Mobile Banking',
    colorHex: 0xFF1E3E93,
  ),
  BankOption(
    id: 'wing',
    shortName: 'WING',
    name: 'Wing Bank',
    subtitle: 'Wing Money App',
    colorHex: 0xFFC41230,
  ),
  BankOption(
    id: 'acleda',
    shortName: 'ACLED',
    name: 'ACLEDA Bank',
    subtitle: 'Unity ToanChet',
    colorHex: 0xFF0B5AA8,
  ),
  BankOption(
    id: 'nbc',
    shortName: 'NBC',
    name: 'Bakong - NBC',
    subtitle: 'National KHQR',
    colorHex: 0xFFC41230,
  ),
  BankOption(
    id: 'prince',
    shortName: 'PRINC',
    name: 'Prince Bank',
    subtitle: 'Prince Mobile',
    colorHex: 0xFF6C2AA6,
  ),
];

final ValueNotifier<BankOption> selectedSubscriptionBank =
    ValueNotifier<BankOption>(subscriptionPassBanks.first);
