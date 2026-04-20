import 'package:flutter/material.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';
import '../state/subscription_pass_bank_state.dart';

class SubscriptionBankSelectionScreen extends StatefulWidget {
  const SubscriptionBankSelectionScreen({
    super.key,
    required this.initialBankId,
  });

  final String initialBankId;

  @override
  State<SubscriptionBankSelectionScreen> createState() =>
      _SubscriptionBankSelectionScreenState();
}

class _SubscriptionBankSelectionScreenState
    extends State<SubscriptionBankSelectionScreen> {
  late String _selectedBankId;

  @override
  void initState() {
    super.initState();
    _selectedBankId = widget.initialBankId;
  }

  @override
  Widget build(BuildContext context) {
    final selectedBank = subscriptionPassBanks.firstWhere(
      (bank) => bank.id == _selectedBankId,
      orElse: () => subscriptionPassBanks.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Bank',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Cambodia · KHQR',
              style: TextStyle(color: Color(0xFFB2B2B2), fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CHOOSE YOUR BANK',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8F8F8F),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: subscriptionPassBanks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bank = subscriptionPassBanks[index];
                    final isSelected = bank.id == _selectedBankId;
                    return _BankTile(
                      bank: bank,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedBankId = bank.id;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'All payments are KHQR-certified and processed securely through the National Bank of Cambodia.',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop<BankOption>(selectedBank),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF15B00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Confirm · ${selectedBank.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    required this.bank,
    required this.isSelected,
    required this.onTap,
  });

  final BankOption bank;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFFF15B00)
        : const Color(0xFFE5E5E5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(bank.colorHex),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bank.shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
                      bank.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      bank.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFFF15B00),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD2D2D2), width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
