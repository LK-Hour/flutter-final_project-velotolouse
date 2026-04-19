import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StationMapQuickActions extends StatelessWidget {
  const StationMapQuickActions({super.key, this.onLocateTap});

  final VoidCallback? onLocateTap;

  @override
  Widget build(BuildContext context) {
    return _StationMapRoundAction(
      actionKey: const Key('quick-action-locate'),
      icon: Icons.gps_fixed_rounded,
      onTap: onLocateTap,
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
  const _StationMapRoundAction({
    required this.icon,
    this.onTap,
    this.actionKey,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: actionKey,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
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
        ),
      ),
    );
  }
}
