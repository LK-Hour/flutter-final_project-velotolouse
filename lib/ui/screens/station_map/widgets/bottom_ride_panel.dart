import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class BottomRidePanel extends StatefulWidget {
  const BottomRidePanel({
    super.key,
    this.onScanTap,
    this.onProfileTap,
    this.onEndRide,
    this.selectedStationName,
    this.activeRideBikeCode,
    this.activeRideStationName,
    this.activeRideStartedAt,
    this.isReturnMode = false,
  });

  final VoidCallback? onScanTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onEndRide;
  final String? selectedStationName;
  final String? activeRideBikeCode;
  final String? activeRideStationName;
  final DateTime? activeRideStartedAt;
  final bool isReturnMode;

  @override
  State<BottomRidePanel> createState() => _BottomRidePanelState();
}

class _BottomRidePanelState extends State<BottomRidePanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant BottomRidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRideStartedAt != widget.activeRideStartedAt) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.activeRideStartedAt == null) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String? rideTimerText = widget.activeRideStartedAt == null
        ? null
        : _formatDuration(
            DateTime.now().difference(widget.activeRideStartedAt!),
          );
    final double panelHeight = rideTimerText == null ? 92 : 176;

    return Container(
      height: panelHeight,
      decoration: const BoxDecoration(
        color: AppColors.baseSurfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(child: _PanelHandle()),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 2,
            child: rideTimerText != null
                ? _ActiveRideContent(
                    rideTimerText: rideTimerText,
                    bikeCode: widget.activeRideBikeCode,
                    stationName:
                        widget.activeRideStationName ??
                        widget.selectedStationName,
                    onEndRide: widget.onEndRide,
                  )
                : _BottomBarContent(
                    onScanTap: widget.onScanTap,
                    onProfileTap: widget.onProfileTap,
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
      height: 58,
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

class _ActiveRideContent extends StatelessWidget {
  const _ActiveRideContent({
    required this.rideTimerText,
    this.bikeCode,
    this.stationName,
    this.onEndRide,
  });

  final String rideTimerText;
  final String? bikeCode;
  final String? stationName;
  final VoidCallback? onEndRide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (bikeCode != null) ...<Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Bike #$bikeCode',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (stationName != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          stationName!,
                          style: const TextStyle(
                            color: AppColors.neutralText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Bike timer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutralText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rideTimerText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              key: const Key('end-ride-button'),
              onPressed: onEndRide,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'End Ride',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
