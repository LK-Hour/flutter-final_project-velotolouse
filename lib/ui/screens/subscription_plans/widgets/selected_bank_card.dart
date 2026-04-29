import 'package:flutter/material.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';

class SelectedBankCard extends StatelessWidget {
  const SelectedBankCard({
    super.key,
    required this.bank,
    required this.onChange,
  });

  final BankOption bank;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF15B00), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(bank.colorHex),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              bank.shortName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bank.name} - KHQR',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Tap to change bank',
                  style: TextStyle(color: Color(0xFFB2B2B2), fontSize: 14),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFFF15B00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
