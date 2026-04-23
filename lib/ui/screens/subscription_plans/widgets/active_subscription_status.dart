import 'package:flutter/material.dart';
import 'package:final_project_velotolouse/ui/widgets/pulsing_highlight_card.dart';
import '../view_model/subscription_pass_view_model.dart';

class ActiveSubscriptionStatus extends StatelessWidget {
  const ActiveSubscriptionStatus({super.key, required this.viewModel});

  final SubscriptionPassViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasActiveSubscription) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PulsingHighlightCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          backgroundColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          pulseColor: const Color(0xFF15803D),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Subscription',
                style: TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You currently have an active ${viewModel.activeSubscription!.planLabel}.',
                style: const TextStyle(color: Color(0xFF15803D), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: viewModel.isProcessing
                ? null
                : () async {
                    final success = await viewModel.cancelSubscription();
                    if (!context.mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Subscription canceled successfully.'),
                        ),
                      );
                    } else if (viewModel.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(viewModel.errorMessage!)),
                      );
                      viewModel.clearError();
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: viewModel.isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFDC2626),
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Cancel Subscription',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }
}
