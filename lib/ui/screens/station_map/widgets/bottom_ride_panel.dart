import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BottomRidePanel extends StatelessWidget {
  const BottomRidePanel({
    super.key,
    this.onScanTap,
    this.onProfileTap,
    this.selectedStationName,
    this.isReturnMode = false,
  });

  final VoidCallback? onScanTap;
  final VoidCallback? onProfileTap;
  final String? selectedStationName;
  final bool isReturnMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: const BoxDecoration(
        color: AppColors.baseSurfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(child: _PanelHandle()),
          ),
          if (!isReturnMode)
            const Positioned(
              top: 22,
              left: 20,
              bottom: 18,
              child: Text(
                'Ready to ride?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          if (isReturnMode)
            const Positioned(
              top: 22,
              left: 20,
              bottom: 18,
              child: Text(
                'Return in progress',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          if (!isReturnMode && selectedStationName != null)
            Positioned(
              top: 46,
              left: 20,
              child: Text(
                selectedStationName!,
                style: const TextStyle(
                  color: AppColors.neutralText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          if (isReturnMode && selectedStationName != null)
            Positioned(
              top: 46,
              left: 20,
              child: Text(
                selectedStationName!,
                style: const TextStyle(
                  color: AppColors.neutralText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          Positioned(
            top: 20,
            right: 16,
            child: Container(
              width: 54,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.baseSurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.baseSurfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 8,
            child: _BottomBarContent(
              onScanTap: onScanTap,
              onProfileTap: onProfileTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHandle extends StatelessWidget {
  const _PanelHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _BottomBarContent extends StatelessWidget {
  const _BottomBarContent({this.onScanTap, this.onProfileTap});

  final VoidCallback? onScanTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: _BottomNavItem(
                      label: 'Ride',
                      icon: Icons.pedal_bike,
                      isSelected: true,
                      onTap: () {},
                    ),
                  ),
                ),
                const SizedBox(width: 74),
                Expanded(
                  child: Center(
                    child: _BottomNavItem(
                      label: 'Profile',
                      icon: Icons.person_outline,
                      onTap: onProfileTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: GestureDetector(
              key: const Key('scan-button'),
              onTap: onScanTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.scanButtonDark,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.warning : AppColors.neutralText;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
