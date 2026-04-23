import re

files = [
    'lib/ui/screens/subscription_plans/passes/annual_pass_screen.dart',
    'lib/ui/screens/subscription_plans/passes/monthly_pass_screen.dart',
    'lib/ui/screens/subscription_plans/passes/daily_pass_screen.dart'
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()

    # The previous regex might have failed or succeeded
    if "class _Body extends StatelessWidget" not in content:
        # Wrap manually
        import_stmt = "import 'package:provider/provider.dart';"
        if import_stmt not in content:
            content = "import 'package:provider/provider.dart';\n" + content
        if "import '../view_model/subscription_pass_view_model.dart';" not in content:
            content = content.replace("import '../widgets/selected_bank_card.dart';", "import '../view_model/subscription_pass_view_model.dart';\nimport '../widgets/selected_bank_card.dart';")

        content = content.replace("Widget build(BuildContext context) {\n    return Scaffold(", """Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionPassViewModel>(
      create: (_) => SubscriptionPassViewModel(
        repository: context.read<InstantPaymentRepository>(),
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(""")

    # Replace ElevatedButton
    if ("consumer<SubscriptionPassViewModel>" not in content.lower()):
        # Replace the button block
        old_button = re.search(r'(?s)SizedBox\(\s*height: 52,\s*child: ElevatedButton\(\s*onPressed: \(\) async \{(.*?)(?:Subscribe • \$[0-9.]* \/ (?:year|month|day).*?),\s*\)\s*\)?\s*\n\s*\),\s*\),', content)
        if old_button:
            print("Found old button in", file)
            # Find plan specifics
            if 'annual' in file:
                plan_id = "'annual'"
                plan_label = "'Annual Pass'"
                amount = "99"
                btn_label = "Subscribe • $99 / year"
            elif 'monthly' in file:
                plan_id = "'monthly'"
                plan_label = "'Monthly Pass'"
                amount = "14.99"
                btn_label = "Subscribe • $14.99 / month"
            else:
                plan_id = "'daily'"
                plan_label = "'Daily Pass'"
                amount = "1.99"
                btn_label = "Subscribe • $1.99 / day"

            replacement = f"""Consumer<SubscriptionPassViewModel>(
                builder: (context, viewModel, _) {{
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: viewModel.isProcessing
                          ? null
                          : () async {{
                              final bank = selectedSubscriptionBank.value;
                              final success = await viewModel.subscribe(
                                planId: {plan_id},
                                planLabel: {plan_label},
                                amountUsd: {amount},
                                bank: bank,
                              );

                              if (!context.mounted) return;

                              if (success) {{
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BookingConfirmationScreen(
                                      paymentLabel: '${{bank.name}} - KHQR',
                                      amountLabel: '\\${amount}',
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
                              '{btn_label}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  );
                }},
              ),"""
            content = content.replace(old_button.group(0), replacement)
            with open(file, 'w') as f:
                f.write(content)

