import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/subscription_plans/mock_instant_payment_repository.dart';
import '../../../domain/model/subscription_plans/bank_option.dart';
import '../../../domain/model/subscription_plans/ride_payment_summary.dart';
import '../../../domain/repositories/subscription_plans/instant_payment_repository.dart';
import 'booking_confirmation_screen.dart';
import 'view_model/instant_payment_view_model.dart';

class InstantPaymentScreen extends StatelessWidget {
  const InstantPaymentScreen({
    super.key,
    this.repository,
  });

  final InstantPaymentRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InstantPaymentViewModel>(
      create: (_) => InstantPaymentViewModel(
        repository: repository ?? MockInstantPaymentRepository(),
      )..load(),
      child: const _InstantPaymentView(),
    );
  }
}

class _InstantPaymentView extends StatelessWidget {
  const _InstantPaymentView();

  @override
  Widget build(BuildContext context) {
    return Consumer<InstantPaymentViewModel>(
      builder: (context, viewModel, _) {
        final selectedBank = viewModel.selectedBank;
        final summary = viewModel.summary;

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
                  'Instant Payment',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pay for this ride',
                  style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: _buildBody(
                context: context,
                viewModel: viewModel,
                selectedBank: selectedBank,
                summary: summary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required InstantPaymentViewModel viewModel,
    required BankOption? selectedBank,
    required RidePaymentSummary? summary,
  }) {
    if (viewModel.isLoading && summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: viewModel.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (summary == null || selectedBank == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RideSummaryCard(summary: summary),
        const SizedBox(height: 12),
        const Text(
          'SELECT YOUR BANK',
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
            itemCount: viewModel.banks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bank = viewModel.banks[index];

              return _BankTile(
                option: bank,
                isSelected: viewModel.selectedBankIndex == index,
                onTap: () => viewModel.selectBank(index),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: viewModel.isPaying
                ? null
                : () async {
                    final success = await viewModel.payNow();
                    if (!context.mounted) {
                      return;
                    }

                    if (success) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookingConfirmationScreen(
                            paymentLabel: '${selectedBank.name} - KHQR',
                            amountLabel:
                                '\$${summary.rideCostUsd.toStringAsFixed(2)}',
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF15B00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: viewModel.isPaying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pay \$${summary.rideCostUsd.toStringAsFixed(2)} with ${selectedBank.shortName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'KHQR certified · Secure payment',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        ),
      ],
    );
  }
}

class _RideSummaryCard extends StatelessWidget {
  const _RideSummaryCard({required this.summary});

  final RidePaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF15B00),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride Cost',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${summary.rideCostUsd.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'USD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  '@${summary.rideCostKhr.toString()} KHR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetricLabel(title: 'Duration', value: summary.duration),
              const SizedBox(height: 12),
              _MetricLabel(
                title: 'Distance',
                value: '${summary.distanceKm.toStringAsFixed(1)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final BankOption option;
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
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(option.colorHex),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  option.shortName,
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
                      option.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF15B00)
                        : const Color(0xFFD7D7D7),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(0xFFF15B00),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
