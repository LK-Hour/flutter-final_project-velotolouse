import 'package:flutter/material.dart';

class PlanTypeChip extends StatelessWidget {
  const PlanTypeChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF15B00) : const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB9B9B9),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
