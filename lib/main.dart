import 'package:flutter/material.dart';

import 'ui/screens/subscription_plans/payment_choice_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeloToulouse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF28C2A)),
        useMaterial3: true,
      ),
      home: const PaymentChoiceScreen(),
    );
  }
}
