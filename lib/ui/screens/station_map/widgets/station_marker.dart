import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StationMarkerWidget extends StatelessWidget {
  const StationMarkerWidget({
    super.key,
    required this.label,
    this.etaLabel,
    required this.isAvailableInCurrentMode,
    required this.isReturnMode,
    required this.isSelected,
    required this.mapPosition,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final String label;
  final String? etaLabel;
  final bool isAvailableInCurrentMode;
  final bool isReturnMode;
  final bool isSelected;
  final Offset mapPosition;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double horizontalOffset = isReturnMode ? 46 : 21;
    final double verticalOffset = isReturnMode ? 22 : 28;

    return Positioned(
      left: (width * mapPosition.dx) - horizontalOffset,
      top: (height * mapPosition.dy) - verticalOffset,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: StationMarkerVisual(
            label: label,
            etaLabel: etaLabel,
            isAvailableInCurrentMode: isAvailableInCurrentMode,
            isReturnMode: isReturnMode,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

class StationMarkerVisual extends StatelessWidget {
  const StationMarkerVisual({
    super.key,
    required this.label,
    this.etaLabel,
    required this.isAvailableInCurrentMode,
    required this.isReturnMode,
    required this.isSelected,
  });

  final String label;
  final String? etaLabel;
  final bool isAvailableInCurrentMode;
  final bool isReturnMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (isReturnMode) {
      return _ReturnDockMarker(
        label: label,
        etaLabel: etaLabel,
        isAvailableInCurrentMode: isAvailableInCurrentMode,
        isSelected: isSelected,
      );
    }

    return _BikePickupMarker(
      label: label,
      isAvailableInCurrentMode: isAvailableInCurrentMode,
      isSelected: isSelected,
    );
  }
}

class _BikePickupMarker extends StatelessWidget {
  const _BikePickupMarker({
    required this.label,
    required this.isAvailableInCurrentMode,
    required this.isSelected,
  });

  final String label;
  final bool isAvailableInCurrentMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isAvailableInCurrentMode
                ? AppColors.warning
                : AppColors.muted,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.scanButtonDark : AppColors.surface,
              width: isSelected ? 2.5 : 3,
            ),
            boxShadow: isSelected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: const Icon(
            Icons.pedal_bike_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isAvailableInCurrentMode
                  ? AppColors.warning
                  : AppColors.neutralText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReturnDockMarker extends StatelessWidget {
  const _ReturnDockMarker({
    required this.label,
    required this.etaLabel,
    required this.isAvailableInCurrentMode,
    required this.isSelected,
  });

  final String label;
  final String? etaLabel;
  final bool isAvailableInCurrentMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color markerColor = isAvailableInCurrentMode
        ? AppColors.success
        : AppColors.muted;
    final Color pointerColor = isSelected && isAvailableInCurrentMode
        ? AppColors.warning
        : markerColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: markerColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 2 : 1.4,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Icon(Icons.arrow_drop_down_rounded, color: pointerColor, size: 16),
        if (etaLabel != null)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neutralText,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              etaLabel!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}
