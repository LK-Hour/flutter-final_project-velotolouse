import os
import re

files = [
    'lib/ui/screens/subscription_plans/passes/annual_pass_screen.dart',
    'lib/ui/screens/subscription_plans/passes/monthly_pass_screen.dart',
    'lib/ui/screens/subscription_plans/passes/daily_pass_screen.dart'
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()

    # Wrap Scaffold with ChangeNotifierProvider
    content = content.replace("return Scaffold(", 
        "return ChangeNotifierProvider(\n      create: (context) => SubscriptionPassViewModel(\n        repository: context.read<InstantPaymentRepository>(),\n      ),\n      child: Scaffold(")
    
    # Close ChangeNotifierProvider at the end of build method
    content = re.sub(r'(\s+\),\s+);\s+\}\s+\}', r'\1,\n      ),\n    );\n  }\n}', content)
    
    # ensure proper imports
    if "import 'package:provider/provider.dart';" not in content:
        content = "import 'package:provider/provider.dart';\n" + content
    
    # add return child to consumer
    # we need to make sure the consumer child syntax is right
    
    with open(file, 'w') as f:
        f.write(content)
