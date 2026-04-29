import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/map_quick_actions.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/search_controls.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/bottom_ride_panel.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_google_map_canvas.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_info_popup.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_search_sheet.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/return_mode_banner_transition.dart';
import 'package:final_project_velotolouse/ui/screens/profile/profile_screen.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:final_project_velotolouse/ui/widgets/ride_completion_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class StationMapScreen extends StatelessWidget {
  const StationMapScreen({super.key});

  static const Map<String, Offset> _markerMapPosition = <String, Offset>{
    'wat-phnom': Offset(0.34, 0.24),
    'central-market': Offset(0.24, 0.55),
    'capitole-square': Offset(0.47, 0.39),
    'independence-monument': Offset(0.64, 0.52),
    'russian-market': Offset(0.74, 0.68),
  };

  Future<void> _onSearchTapped(
    BuildContext context,
    StationMapViewModel viewModel,
  ) async {
    final String? selectedStationId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.baseSurfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: StationSearchSheet(
            onSearch: viewModel.searchStations,
            onSelectStation: (String stationId) {
              Navigator.of(context).pop(stationId);
            },
            isReturnMode: viewModel.isReturnMode,
            availabilityLabelForStation:
                viewModel.availabilityLabelForCurrentMode,
            canSelectStation: viewModel.hasAvailabilityForCurrentMode,
          ),
        );
      },
    );

    if (!context.mounted || selectedStationId == null) {
      return;
    }
    viewModel.selectStation(selectedStationId);
  }

  Future<void> _onEndRidePressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) async {
    final String? sessionId = viewModel.activeRideSessionId;
    final DateTime? startedAt = viewModel.activeRideStartedAt;
    final String? bikeCode = viewModel.activeRideBikeCode;
    final String? stationName = viewModel.activeRideStationName;
    if (sessionId == null || startedAt == null) {
      return;
    }

    final String? returnStationId = viewModel.selectedStation?.id;
    final String returnStationName =
        viewModel.selectedStation?.name ?? stationName ?? 'Unknown station';

    try {
      final rideRepo = context.read<RideRepository>();
      final bikeRepo = context.read<BikeRepository>();
      final activeRide = await rideRepo.getActiveRide();
      if (activeRide != null) {
        await Future.wait([
          rideRepo.endRide(sessionId),
          bikeRepo.lockBike(
            activeRide.bikeCode,
            returnStationId: returnStationId,
          ),
        ]);
      }

      if (!context.mounted) return;

      viewModel.endActiveRide();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return RideCompletionModal(
            bikeCode: bikeCode ?? 'Unknown bike',
            stationName: returnStationName,
            rideDuration: _formatRideDuration(startedAt),
            onDone: () {
              Navigator.of(dialogContext).pop();
            },
          );
        },
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to end ride. Please try again.')),
      );
    }
  }

  void _onReturnModeBannerClose(StationMapViewModel viewModel) {
    viewModel.dismissReturnModeBanner();
  }

  Future<void> _onLocateCurrentPositionPressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) async {
    final UserLocationStatus status = await viewModel.locateCurrentUser();
    if (!context.mounted) {
      return;
    }

    final String message = switch (status) {
      UserLocationStatus.located => 'Centered on your current location.',
      UserLocationStatus.permissionDenied =>
        'Location permission denied. Please allow GPS access.',
      UserLocationStatus.permissionDeniedForever =>
        'Location permission denied permanently. Enable it in settings.',
      UserLocationStatus.serviceDisabled =>
        'GPS is off. Please enable location services.',
      UserLocationStatus.unavailable => 'Unable to find your current location.',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onStationMarkerTapped(
    BuildContext context,
    StationMapViewModel viewModel,
    String stationId,
  ) async {
    viewModel.selectStation(stationId);
    final Iterable<Station> matches =
        viewModel.stations.where((Station s) => s.id == stationId);
    if (matches.isEmpty || !context.mounted) return;
    final Station station = matches.first;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: StationInfoPopup(
          station: station,
          isReturnMode: viewModel.isReturnMode,
          onNavigate: () async {
            Navigator.of(context).pop();
            final UserLocationStatus status =
                await viewModel.showRouteToStation(station);
            if (!context.mounted || status == UserLocationStatus.located) {
              return;
            }
            final String message = switch (status) {
              UserLocationStatus.permissionDenied =>
                'Location permission denied. Please allow GPS access.',
              UserLocationStatus.permissionDeniedForever =>
                'Location permission denied permanently. Enable it in settings.',
              UserLocationStatus.serviceDisabled =>
                'GPS is off. Please enable location services.',
              UserLocationStatus.unavailable =>
                'Unable to get your current location.',
              UserLocationStatus.located => '',
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        ),
      ),
    );
  }

  void _onProfilePressed(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  String _formatRideDuration(DateTime startedAt) {
    final Duration elapsed = DateTime.now().difference(startedAt);
    final int hours = elapsed.inHours;
    final int minutes = elapsed.inMinutes.remainder(60);
    final int seconds = elapsed.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final StationMapViewModel viewModel = context.watch<StationMapViewModel>();
    final Station? selectedStation = viewModel.selectedStation;
    return Scaffold(
      backgroundColor: AppColors.baseSurfaceAlt,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                color: AppColors.mapBackground,
                child: Stack(
                  children: <Widget>[
                    if (viewModel.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (viewModel.errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: viewModel.loadStations,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: StationGoogleMapCanvas(
                          stations: viewModel.stations,
                          isReturnMode: viewModel.isReturnMode,
                          selectedStation: selectedStation,
                          mapCenter: viewModel.mapCenter,
                          currentUserLocation: viewModel.currentUserLocation,
                          routePath: viewModel.activeRoutePath,
                          locateRequestVersion: viewModel.locateRequestVersion,
                          fallbackMarkerPositions: _markerMapPosition,
                          onStationTap: (String id) =>
                              _onStationMarkerTapped(context, viewModel, id),
                          onMapTap: viewModel.clearSelectedStation,
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: ReturnModeBannerTransition(
                        visible: viewModel.showReturnModeBanner,
                        onClose: () => _onReturnModeBannerClose(viewModel),
                      ),
                    ),
                    if (!viewModel.showReturnModeBanner)
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 12,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: StationMapSearchField(
                                placeholderText: viewModel.isReturnMode
                                    ? 'Find a station with free docks...'
                                    : 'Find a station or destination...',
                                onTap: () =>
                                    _onSearchTapped(context, viewModel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      right: 14,
                      bottom: 150,
                      child: StationMapQuickActions(
                        onLocateTap: () =>
                            _onLocateCurrentPositionPressed(context, viewModel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomRidePanel(
                selectedStationName: selectedStation?.name,
                isReturnMode: viewModel.isReturnMode,
                activeRideBikeCode: viewModel.activeRideBikeCode,
                activeRideStationName: viewModel.activeRideStationName,
                activeRideStartedAt: viewModel.activeRideStartedAt,
                onScanTap: null,
                onProfileTap: viewModel.hasActiveRide
                    ? null
                    : () => _onProfilePressed(context),
                onEndRide: viewModel.hasActiveRide
                    ? () => _onEndRidePressed(context, viewModel)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
