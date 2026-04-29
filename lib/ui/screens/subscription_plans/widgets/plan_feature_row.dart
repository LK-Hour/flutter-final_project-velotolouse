import 'package:flutter/material.dart';

class PlanFeatureRow extends StatelessWidget {
  const PlanFeatureRow({
    super.key,
    required this.text,
    required this.enabled,
  });

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconBg = enabled ? const Color(0xFFFCEDE5) : const Color(0xFFF2F2F2);
    final iconColor = enabled ? const Color(0xFFF15B00) : const Color(0xFFD5D5D5);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? const Color(0xFF2C2C2C) : const Color(0xFFD0D0D0),
            ),
          ),
        ),
      ],
    );
  }
}
