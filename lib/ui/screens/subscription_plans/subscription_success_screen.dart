import 'package:flutter/material.dart';

import '../../../domain/model/subscription_plans/payment_transactions.dart';
import '../qr_scanner/qr_scanner_screen.dart';

class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({
    super.key,
    required this.subscription,
    required this.planName,
    required this.amountPaid,
    required this.paymentMethod,
  });

  final SubscriptionTransaction subscription;
  final String planName;
  final String amountPaid;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text(
          'Subscription Success',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCEDE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFFF15B00),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You\'re Subscribed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You have successfully subscribed to the $planName plan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Plan', value: planName),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _DetailRow(label: 'Amount Paid', value: amountPaid),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _DetailRow(label: 'Payment Method', value: paymentMethod),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            QrScannerScreen(showDemoScanButton: true),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18A957),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Start Ride',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(subscription);
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
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8F8F8F), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2A2A2A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
