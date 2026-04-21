import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';
import '../../../../domain/repositories/subscription_plans/instant_payment_repository.dart';
import '../booking_confirmation_screen.dart';
import '../state/subscription_pass_bank_state.dart';
import '../widgets/plan_feature_row.dart';
import '../widgets/plan_type_chip.dart';
import '../widgets/selected_bank_card.dart';
import 'daily_pass_screen.dart';
import 'monthly_pass_screen.dart';
import 'subscription_bank_selection_screen.dart';

class AnnualPassScreen extends StatelessWidget {
  const AnnualPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Subscription Plans',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Ride more, save more',
              style: TextStyle(color: Color(0xFFB2B2B2), fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PlanTypeChip(
                      label: 'Daily',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const DailyPassScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PlanTypeChip(
                      label: 'Monthly',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const MonthlyPassScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: PlanTypeChip(label: 'Annual', selected: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF15B00), width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEDE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🔥 Best value — save 45%',
                        style: TextStyle(
                          color: Color(0xFFF15B00),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Annual Pass',
                      style: TextStyle(
                        color: Color(0xFF2C2C2C),
                        fontSize: 38,
                        height: 0.85,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$99',
                          style: TextStyle(
                            color: Color(0xFFF15B00),
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            height: 0.9,
                          ),
                        ),
                        SizedBox(width: 6),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '/ year',
                            style: TextStyle(
                              color: Color(0xFF9B9B9B),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Just \$8.25/month. Smartest way to ride.',
                      style: TextStyle(color: Color(0xFFB1B1B1), fontSize: 21),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFF0F0F0), height: 1),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'Everything in Monthly, all year',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'Unlimited 60-min rides',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'E-bike + priority unlock',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'Save \$80.88 vs monthly billing',
                      enabled: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<BankOption>(
                valueListenable: selectedSubscriptionBank,
                builder: (context, bank, _) {
                  return SelectedBankCard(
                    bank: bank,
                    onChange: () async {
                      final selected = await Navigator.of(context).push<BankOption>(
                        MaterialPageRoute<BankOption>(
                          builder: (_) => SubscriptionBankSelectionScreen(
                            initialBankId: bank.id,
                          ),
                        ),
                      );

                      if (selected != null) {
                        selectedSubscriptionBank.value = selected;
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final bank = selectedSubscriptionBank.value;
                    try {
                      await context
                          .read<InstantPaymentRepository>()
                          .createSubscriptionTransaction(
                            planId: 'annual',
                            planLabel: 'Annual Pass',
                            amountUsd: 99,
                            bank: bank,
                          );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to save subscription. Please try again.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BookingConfirmationScreen(
                          paymentLabel: '${bank.name} - KHQR',
                          amountLabel: '\$99',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF15B00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Subscribe • \$99 / year',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Billed once yearly · Cancel anytime',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFC1C1C1), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
