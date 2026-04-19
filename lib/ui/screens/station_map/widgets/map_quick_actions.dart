import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StationMapQuickActions extends StatelessWidget {
  const StationMapQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        _StationMapRoundAction(icon: Icons.gps_fixed_rounded),
        SizedBox(height: 10),
        _StationMapRoundAction(icon: Icons.layers_outlined),
      ],
    );
  }
}

class StationMapPinDot extends StatelessWidget {
  const StationMapPinDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }
}

class _StationMapRoundAction extends StatelessWidget {
  const _StationMapRoundAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: AppColors.slate),
    );
  }
}
