import 'package:final_project_velotolouse/data/repositories/bikes/firebase_station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/model/stations/station_bike_inventory_item.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StationInfoPopup extends StatelessWidget {
  const StationInfoPopup({
    super.key,
    required this.station,
    required this.isReturnMode,
    required this.onClose,
    required this.onNavigate,
    required this.onReturnBike,
    this.onViewBikes,
  });

  final Station station;
  final bool isReturnMode;
  final VoidCallback onClose;
  final VoidCallback onNavigate;
  final VoidCallback onReturnBike;
  final VoidCallback? onViewBikes;

  @override
  Widget build(BuildContext context) {
    final StationBikeInventoryRepository bikeRepository =
        Provider.of<StationBikeInventoryRepository?>(context, listen: false) ??
        FirebaseStationBikeInventoryRepository();
    final double maxPopupHeight = MediaQuery.sizeOf(context).height * 0.42;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxPopupHeight),
      child: Container(
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
        child: SingleChildScrollView(
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: isReturnMode ? onReturnBike : onNavigate,
                      child: Text(
                        isReturnMode ? 'Return Bike Here' : 'Navigate Here',
                      ),
                    ),
                  ),
                ],
              ),
              if (!isReturnMode && onViewBikes != null) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onViewBikes,
                    child: const Text('View Bikes'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _BikeInventoryPreview(
                station: station,
                repository: bikeRepository,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BikeInventoryPreview extends StatefulWidget {
  const _BikeInventoryPreview({
    required this.station,
    required this.repository,
  });

  final Station station;
  final StationBikeInventoryRepository repository;

  @override
  State<_BikeInventoryPreview> createState() => _BikeInventoryPreviewState();
}

class _BikeInventoryPreviewState extends State<_BikeInventoryPreview> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StationBikeInventoryItem>>(
      future: widget.repository.fetchBikesForStation(widget.station.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }

        final List<StationBikeInventoryItem> items =
            snapshot.data ?? const <StationBikeInventoryItem>[];
        final int liveBikeCount = items
            .where((item) => item.isAvailable)
            .length;
        final int unavailableBikeCount = items.length - liveBikeCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _StationInfoPill(
                    label: 'Available Bikes',
                    value: '$liveBikeCount',
                    backgroundColor: AppColors.success.withOpacity(0.12),
                    valueColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StationInfoPill(
                    label: 'Unavailable Bikes',
                    value: '$unavailableBikeCount',
                    backgroundColor: AppColors.baseSurface,
                    valueColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Bike Slots',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _BikeSlotRow(item: items[index]);
              },
            ),
          ],
        );
      },
    );
  }
}

class _BikeSlotRow extends StatelessWidget {
  const _BikeSlotRow({required this.item});

  final StationBikeInventoryItem item;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item.isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE7F7EC) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF2FB463)
                  : const Color(0xFFD7D7D7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.slotId.replaceAll(RegExp(r'[^0-9]'), ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF2FB463)
                  : const Color(0xFFCDCDCD),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              isAvailable ? Icons.pedal_bike : Icons.do_not_disturb_on_outlined,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.bikeCode ?? 'Unavailable bike',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAvailable ? 'Available' : 'Unavailable bike',
                  style: TextStyle(
                    color: isAvailable
                        ? const Color(0xFF2FB463)
                        : AppColors.neutralText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 30,
            child: FilledButton(
              onPressed: isAvailable ? () {} : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF15B00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFDEDEDE),
                disabledForegroundColor: const Color(0xFF9B9B9B),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Scan',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationInfoPill extends StatelessWidget {
  const _StationInfoPill({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: valueColor,
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
    );
  }
}
