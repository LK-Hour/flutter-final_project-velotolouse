import re
import os

files = [
    'lib/ui/screens/subscription_plans/passes/annual_pass_screen.dart',
    'lib/ui/screens/subscription_plans/passes/monthly_pass_screen.dart',
    'lib/ui/screens/subscription_plans/passes/daily_pass_screen.dart'
]

for file_path in files:
    with open(file_path, 'r') as f:
        content = f.read()

    # Find class name
    class_match = re.search(r'class (\w+Screen) extends StatelessWidget \{', content)
    if not class_match:
        continue
    class_name = class_match.group(1)

    # Replace class start and build to inject ChangeNotifierProvider
    content = content.replace(f"class {class_name} extends StatelessWidget {{\n  const {class_name}({{super.key}});", 
        f"class {class_name} extends StatelessWidget {{\n  const {class_name}({{super.key}});\n")

    build_method_start = "  Widget build(BuildContext context) {\n    return Scaffold("
    provider_wrap = """  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SubscriptionPassViewModel(
        repository: context.read<InstantPaymentRepository>(),
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold("""

    content = content.replace(build_method_start, provider_wrap)
    
    # Imports
    if "import '../view_model/subscription_pass_view_model.dart';" not in content:
        content = content.replace("import '../widgets/selected_bank_card.dart';", 
                                  "import '../view_model/subscription_pass_view_model.dart';\nimport '../widgets/selected_bank_card.dart';")
        content = content.replace("import 'package:flutter/material.dart';", 
                                  "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';")

    # Replace ElevatedButton logic
    if 'annual' in file_path:
        plan_id = "'annual'"
        plan_label = "'Annual Pass'"
        amount = "99"
        btn_label = "Subscribe • $99 / year"
    elif 'monthly' in file_path:
        plan_id = "'monthly'"
        plan_label = "'Monthly Pass'"
        amount = "14.99"
        btn_label = "Subscribe • $14.99 / month"
    else:
        plan_id = "'daily'"
        plan_label = "'Daily Pass'"
        amount = "1.99"
        btn_label = "Subscribe • $1.99 / day"

    button_pattern = r"(?s)SizedBox\(\s*height: 52,\s*child: ElevatedButton\(\s*onPressed: \(\) async \{.*?(?=\s*style: ElevatedButton\.styleFrom)"
    
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
                      """
    
    content = re.sub(button_pattern, replacement, content)
    
    # Close Consumer
    content = content.replace("), // ElevatedButton", ")")
    # Actually wait. Let's do it cleaner to make sure the closing parameters match.
    # The original is:
    #                 child: const Text(...)
    #               ),
    #             ),
    content = re.sub(rf"(?s)child: const Text\(\s*'{btn_label}',\s*style: TextStyle\(fontWeight: FontWeight.w700, fontSize: 16\),\s*\),\s*\),\s*\),", 
                     f"child: viewModel.isProcessing\n                          ? const SizedBox(\n                              height: 24,\n                              width: 24,\n                              child: CircularProgressIndicator(\n                                color: Colors.white,\n                                strokeWidth: 2.5,\n                              ),\n                            )\n                          : const Text(\n                              '{btn_label}',\n                              style: TextStyle(\n                                fontWeight: FontWeight.w700,\n                                fontSize: 16,\n                              ),\n                            ),\n                    ),\n                  );\n                }},\n              ),", content)

    # Deduplicate provider imports if it double generated earlier
    import_matches = len(re.findall(r"import 'package:provider/provider.dart';", content))
    if import_matches > 1:
        content = content.replace("import 'package:provider/provider.dart';\n", "", import_matches - 1)

    with open(file_path, 'w') as f:
        f.write(content)

print('done')
