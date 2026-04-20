import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StationInfoPopup extends StatelessWidget {
  const StationInfoPopup({
    super.key,
    required this.station,
    required this.isReturnMode,
    required this.onClose,
    required this.onNavigate,
    required this.onReturnBike,
    required this.onViewStation,
  });

  final Station station;
  final bool isReturnMode;
  final VoidCallback onClose;
  final VoidCallback onNavigate;
  final VoidCallback onReturnBike;
  final VoidCallback onViewStation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.neutralText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            station.address,
            style: const TextStyle(
              color: AppColors.neutralText,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _StationInfoPill(
                label: isReturnMode ? 'Free Docks' : 'Available Bikes',
                value: isReturnMode
                    ? '${station.freeDocks}'
                    : '${station.availableBikes}',
              ),
              const SizedBox(width: 8),
              _StationInfoPill(
                label: isReturnMode ? 'Total Capacity' : 'Empty Slots',
                value: isReturnMode
                    ? '${station.totalCapacity}'
                    : '${station.freeDocks}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
            child: const Text('Close'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: isReturnMode ? onReturnBike : onNavigate,
                  child: Text(
                    isReturnMode ? 'Return Bike Here' : 'Navigate Here',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onViewStation,
                  child: const Text('View Station'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StationInfoPill extends StatelessWidget {
  const _StationInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.baseSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.neutralText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
