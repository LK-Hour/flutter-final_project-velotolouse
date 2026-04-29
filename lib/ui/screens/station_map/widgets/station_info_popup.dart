import 'package:final_project_velotolouse/data/repositories/bikes/firebase_station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/model/stations/station_bike_inventory_item.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/screens/active_ride/active_ride_screen.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StationInfoPopup extends StatelessWidget {
  const StationInfoPopup({
    super.key,
    required this.station,
    required this.isReturnMode,
    required this.onNavigate,
  });

  final Station station;
  final bool isReturnMode;
  final VoidCallback onNavigate;

  Future<void> _onUnlockBike(
    BuildContext context,
    StationBikeInventoryItem item,
  ) async {
    final rideRepo = context.read<RideRepository>();
    final bikeRepo = context.read<BikeRepository>();
    final bikeCode = item.bikeCode ?? item.slotId;

    final activeRide = await rideRepo.getActiveRide();
    if (!context.mounted) return;

    if (activeRide != null) {
      try {
        context.read<StationMapViewModel>().activateRide(
          sessionId: activeRide.id,
          startedAt: activeRide.startedAt,
          bikeCode: activeRide.bikeCode,
          stationName: station.name,
        );
      } catch (_) {}
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: activeRide.bikeCode,
            stationName: station.name,
            sessionId: activeRide.id,
          ),
        ),
      );
      return;
    }

    try {
      final activeSession = await rideRepo.startRide(
        bikeCode: bikeCode,
        stationId: station.id,
      );
      await bikeRepo.unlockBike(bikeCode);
      if (!context.mounted) return;

      try {
        context.read<StationMapViewModel>().activateRide(
          sessionId: activeSession.id,
          startedAt: activeSession.startedAt,
          bikeCode: activeSession.bikeCode,
          stationName: station.name,
        );
      } catch (_) {}

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActiveRideScreen(
            bikeCode: activeSession.bikeCode,
            stationName: station.name,
            sessionId: activeSession.id,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlock bike: $e')),
      );
    }
  }

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
              if (isReturnMode) ...<Widget>[
                _ReturnModeSummary(station: station),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onNavigate,
                    child: const Text('Navigate Here'),
                  ),
                ),
              ] else ...<Widget>[
                _BikeInventoryPreview(
                  station: station,
                  repository: bikeRepository,
                  onUnlock: (StationBikeInventoryItem item) =>
                      _onUnlockBike(context, item),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        onPressed: onNavigate,
                        child: const Text('Navigate Here'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnModeSummary extends StatelessWidget {
  const _ReturnModeSummary({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final bool isFull = station.freeDocks <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFull ? const Color(0xFFFFF1E8) : AppColors.baseSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFull ? const Color(0xFFF5B38A) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Return mode',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _StationInfoPill(
                  label: 'Free docks',
                  value: '${station.freeDocks}',
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StationInfoPill(
                  label: 'Total capacity',
                  value: '${station.totalCapacity}',
                  backgroundColor: AppColors.baseSurface,
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (isFull) ...<Widget>[
            const SizedBox(height: 10),
            const Text(
              'This station is full. Choose another dock if you want to return the bike.',
              style: TextStyle(
                color: AppColors.neutralText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BikeInventoryPreview extends StatefulWidget {
  const _BikeInventoryPreview({
    required this.station,
    required this.repository,
    required this.onUnlock,
  });

  final Station station;
  final StationBikeInventoryRepository repository;
  final ValueChanged<StationBikeInventoryItem> onUnlock;

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
        final int emptySlotCount = widget.station.totalCapacity - liveBikeCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _StationInfoPill(
                    label: 'Available Bikes',
                    value: '$liveBikeCount',
                    backgroundColor: AppColors.success.withValues(alpha: 0.12),
                    valueColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StationInfoPill(
                    label: 'Unavailable Bikes',
                    value: '$emptySlotCount',
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
                Text(
                  'Swipe left to unlock',
                  style: TextStyle(
                    color: AppColors.neutralText.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _BikeSlotRow(
                  item: items[index],
                  onUnlock: () => widget.onUnlock(items[index]),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BikeSlotRow extends StatefulWidget {
  const _BikeSlotRow({required this.item, this.onUnlock});

  final StationBikeInventoryItem item;
  final VoidCallback? onUnlock;

  @override
  State<_BikeSlotRow> createState() => _BikeSlotRowState();
}

class _BikeSlotRowState extends State<_BikeSlotRow> {
  double _dragX = 0;
  bool _triggered = false;

  static const double _maxReveal = 80.0;
  static const double _threshold = 60.0;

  void _onDragUpdate(DragUpdateDetails d) {
    if (!widget.item.isAvailable || _triggered) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(-_maxReveal, 0.0);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (!widget.item.isAvailable || _triggered) return;
    if (_dragX <= -_threshold) {
      setState(() {
        _triggered = true;
        _dragX = -_maxReveal;
      });
      widget.onUnlock?.call();
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = widget.item.isAvailable;
    final double revealRatio = (-_dragX / _maxReveal).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            // Revealed unlock background
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF15B00),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 18),
                child: Opacity(
                  opacity: revealRatio,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Unlock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Foreground row content
            Transform.translate(
              offset: Offset(_dragX, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFE7F7EC)
                      : const Color(0xFFF3F3F3),
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
                        widget.item.slotId.replaceAll(RegExp(r'[^0-9]'), ''),
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
                        isAvailable
                            ? Icons.pedal_bike
                            : Icons.do_not_disturb_on_outlined,
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
                            widget.item.bikeCode ?? 'Unavailable bike',
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
                    const SizedBox(width: 8),
                    if (_triggered)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF15B00),
                        ),
                      )
                    else if (isAvailable)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
