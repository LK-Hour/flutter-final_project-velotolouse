import re

files = [
    ('lib/ui/screens/subscription_plans/passes/annual_pass_screen.dart', 'annual', 'Annual Pass', 99, 'year'),
    ('lib/ui/screens/subscription_plans/passes/monthly_pass_screen.dart', 'monthly', 'Monthly Pass', 14.99, 'month'),
    ('lib/ui/screens/subscription_plans/passes/daily_pass_screen.dart', 'daily', 'Daily Pass', 1.99, 'day')
]

for file, planId, planLabel, amount, period in files:
    with open(file, 'r') as f:
        c = f.read()

    # 1. Imports
    if "import '../view_model/subscription_pass_view_model.dart';" not in c:
        c = c.replace("import '../widgets/selected_bank_card.dart';", 
            "import '../view_model/subscription_pass_view_model.dart';\nimport '../widgets/selected_bank_card.dart';")

    class_name = file.split('/')[-1].split('_')[0].capitalize() + 'PassScreen'
    
    # 2. Add ChangeNotifierProvider.
    c = c.replace(
        "Widget build(BuildContext context) {\n    return Scaffold(",
        f"""Widget build(BuildContext context) {{
    return ChangeNotifierProvider<SubscriptionPassViewModel>(
      create: (context) => SubscriptionPassViewModel(
        repository: context.read<InstantPaymentRepository>(),
      ),
      child: const _Body(),
    );
  }}
}}

class _Body extends StatelessWidget {{
  const _Body();

  @override
  Widget build(BuildContext context) {{
    return Scaffold("""
    )

    # 3. Handle ElevatedButton area replacement
    btn_start = r'              SizedBox\(\s*height: 52,\s*child: ElevatedButton\('
    import re
    # We locate the exact slice
    idx_btn = c.find('              SizedBox(\n                height: 52,\n                child: ElevatedButton(')

    idx_title = c.find("              const SizedBox(height: 8),\n              const Text(", idx_btn)
    
    if idx_btn != -1 and idx_title != -1:
        # Construct new button
        new_amount_str = str(amount)
        if new_amount_str.endswith(".0"): 
            new_amount_str = new_amount_str[:-2]

        new_button = f"""              Consumer<SubscriptionPassViewModel>(
                builder: (context, viewModel, _) {{
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: viewModel.isProcessing
                          ? null
                          : () async {{
                              final bank = selectedSubscriptionBank.value;
                              final success = await viewModel.subscribe(
                                planId: '{planId}',
                                planLabel: '{planLabel}',
                                amountUsd: {amount},
                                bank: bank,
                              );

                              if (!context.mounted) return;

                              if (success) {{
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BookingConfirmationScreen(
                                      paymentLabel: '${{bank.name}} - KHQR',
                                      amountLabel: '\\${new_amount_str}',
                                    ),
                                  ),
                                );
                              }} else if (viewModel.errorMessage != null) {{
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(viewModel.errorMessage!),
                                  ),
                                );
                                viewModel.clearError();
                              }}
                            }},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15B00),
                        foregroundColor: Colors.white,
                        elevation: 0,
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
                          : const Text(
                              'Subscribe • \\${new_amount_str} / {period}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  );
                }},
              ),
"""
        c = c[:idx_btn] + new_button + c[idx_title:]

    with open(file, 'w') as f:
        f.write(c)

