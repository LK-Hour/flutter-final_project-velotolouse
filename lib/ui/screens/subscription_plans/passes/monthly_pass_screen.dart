import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/model/subscription_plans/bank_option.dart';
import '../../../../domain/model/subscription_plans/subscription_transaction.dart';
import '../../../../domain/repositories/subscription_plans/instant_payment_repository.dart';
import '../widgets/active_subscription_status.dart';
import '../subscription_success_screen.dart';
import '../state/subscription_pass_bank_state.dart';
import '../widgets/plan_feature_row.dart';
import '../widgets/plan_type_chip.dart';
import '../view_model/subscription_pass_view_model.dart';
import '../widgets/selected_bank_card.dart';
import 'annual_pass_screen.dart';
import 'daily_pass_screen.dart';
import 'subscription_bank_selection_screen.dart';

class MonthlyPassScreen extends StatelessWidget {
  const MonthlyPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionPassViewModel>(
      create: (context) => SubscriptionPassViewModel(
        repository: context.read<InstantPaymentRepository>(),
      )..loadActiveSubscription(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

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
                  const Expanded(
                    child: PlanTypeChip(label: 'Monthly', selected: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PlanTypeChip(
                      label: 'Annual',
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const AnnualPassScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF15B00), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEDE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '* Most popular',
                        style: TextStyle(
                          color: Color(0xFFF15B00),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Monthly Pass',
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
                          '\$14.99',
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
                            '/ month',
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
                      'Best value for daily commuters.',
                      style: TextStyle(color: Color(0xFFB1B1B1), fontSize: 21),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFF0F0F0), height: 1),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'Unlimited 45-min rides all month',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'All stations in Phnom Penh',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'E-bike access included',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    const PlanFeatureRow(
                      text: 'Priority unlock at busy stations',
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
                      final selected = await Navigator.of(context)
                          .push<BankOption>(
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
              Consumer<SubscriptionPassViewModel>(
                builder: (context, viewModel, _) {
                  return ActiveSubscriptionStatus(viewModel: viewModel);
                },
              ),
              const SizedBox(height: 12),
              Consumer<SubscriptionPassViewModel>(
                builder: (context, viewModel, _) {
                  final isSubscribeDisabled =
                      viewModel.isProcessing || viewModel.hasActiveSubscription;

                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubscribeDisabled
                          ? null
                          : () async {
                              final bank = selectedSubscriptionBank.value;
                              final success = await viewModel.subscribe(
                                planId: 'monthly',
                                planLabel: 'Monthly Pass',
                                amountUsd: 14.99,
                                bank: bank,
                              );

                              if (!context.mounted) return;

                              if (success) {
                                final subscription =
                                    viewModel.activeSubscription;
                                if (subscription == null) {
                                  return;
                                }

                                final result = await Navigator.of(context)
                                    .push<SubscriptionTransaction>(
                                      MaterialPageRoute<
                                        SubscriptionTransaction
                                      >(
                                        builder: (_) =>
                                            SubscriptionSuccessScreen(
                                              subscription: subscription,
                                              planName: 'Monthly Pass',
                                              amountPaid: '\$14.99',
                                              paymentMethod:
                                                  '${bank.name} - KHQR',
                                            ),
                                      ),
                                    );

                                if (!context.mounted) return;
                                if (result != null) {
                                  Navigator.of(context).pop(result);
                                }
                              } else if (viewModel.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(viewModel.errorMessage!),
                                  ),
                                );
                                viewModel.clearError();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15B00),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFE8E8E8),
                        disabledForegroundColor: const Color(0xFF9D9D9D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: viewModel.isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : viewModel.hasActiveSubscription
                          ? const Text(
                              'Subscription Active',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            )
                          : const Text(
                              'Subscribe - \$14.99 / month',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Renews monthly - Cancel anytime',
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
