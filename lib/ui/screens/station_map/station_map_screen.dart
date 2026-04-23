import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/bottom_ride_panel.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/map_quick_actions.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/search_controls.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_google_map_canvas.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_info_popup.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_reroute_alert.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_search_sheet.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/return_mode_banner_transition.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/station_bike_inventory_screen.dart';
import 'package:final_project_velotolouse/ui/screens/profile/profile_screen.dart';
import 'package:final_project_velotolouse/ui/screens/qr_scanner/qr_scanner_screen.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void _onTopRightButtonTapped(BuildContext context) {
    if (kDebugMode) {
      context.read<StationMapViewModel>().toggleReturnModeForTesting();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Return mode switches automatically after bike booking.'),
      ),
    );
  }

  void _onScanButtonPressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const QrScannerScreen(showDemoScanButton: true),
      ),
    );
  }

  Future<void> _onEndRidePressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) async {
    final String? sessionId = viewModel.activeRideSessionId;
    final DateTime? startedAt = viewModel.activeRideStartedAt;
    if (sessionId == null || startedAt == null) {
      return;
    }

    try {
      final rideRepo = context.read<RideRepository>();
      final bikeRepo = context.read<BikeRepository>();
      final activeRide = await rideRepo.getActiveRide();
      if (activeRide != null) {
        await Future.wait([
          rideRepo.endRide(sessionId),
          bikeRepo.lockBike(activeRide.bikeCode),
        ]);
      }

      if (!context.mounted) return;

      viewModel.endActiveRide();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ride ended successfully.')));
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

  Future<void> _onNavigateHerePressed(
    BuildContext context,
    StationMapViewModel viewModel,
    Station station,
  ) async {
    final UserLocationStatus status = await viewModel.showRouteToStation(
      station,
    );
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
      UserLocationStatus.unavailable => 'Unable to get your current location.',
      UserLocationStatus.located => '',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onReturnBikePressed(
    BuildContext context,
    StationMapViewModel viewModel,
    Station station,
  ) async {
    final String? sessionId = viewModel.activeRideSessionId;
    final String? bikeCode = viewModel.activeRideBikeCode;
    if (sessionId == null || bikeCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active ride to return.')),
      );
      return;
    }

    final bool isStationFull = viewModel.isReturnMode
        ? viewModel.showFullStationRerouteAlert
        : station.freeDocks <= 0;
    if (isStationFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This station is full. Please choose another dock.'),
        ),
      );
      return;
    }

    try {
      final rideRepo = context.read<RideRepository>();
      final bikeRepo = context.read<BikeRepository>();
      final activeRide = await rideRepo.getActiveRide();
      if (activeRide == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active ride to return.')),
        );
        return;
      }

      await Future.wait([
        rideRepo.endRide(sessionId),
        bikeRepo.lockBike(bikeCode),
      ]);

      if (!context.mounted) return;

      viewModel.endActiveRide();
      await viewModel.loadStations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bike returned successfully.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to return bike. Please try again.'),
        ),
      );
    }
  }

  void _onRerouteToDockPressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) {
    final Station? suggestion = viewModel.suggestedAlternativeDockStation;
    viewModel.rerouteToSuggestedDock();
    if (suggestion == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Rerouted to ${suggestion.name}.')));
  }

  void _onRerouteToBikePressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) {
    final Station? suggestion = viewModel.suggestedAlternativeBikeStation;
    viewModel.rerouteToSuggestedBikeStation();
    if (suggestion == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Rerouted to ${suggestion.name}.')));
  }

  void _onViewBikesPressed(BuildContext context, Station station) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StationBikeInventoryScreen(station: station),
      ),
    );
  }

  void _onProfilePressed(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final StationMapViewModel viewModel = context.watch<StationMapViewModel>();
    final Station? selectedStation = viewModel.selectedStation;
    final double bottomPanelHeight = viewModel.activeRideStartedAt == null
        ? 138
        : 176;
    final double popupBottomOffset = bottomPanelHeight - 50;

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
                          onStationTap: viewModel.selectStation,
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
                            if (!viewModel.isReturnMode) ...<Widget>[
                              const SizedBox(width: 10),
                              StationMapModeButton(
                                isReturnMode: viewModel.isReturnMode,
                                onTap: () => _onTopRightButtonTapped(context),
                              ),
                            ],
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
                    if (selectedStation != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: popupBottomOffset,
                        child: viewModel.showFullStationRerouteAlert
                            ? StationRerouteAlert(
                                selectedStation: selectedStation,
                                suggestedStation:
                                    viewModel.suggestedAlternativeDockStation,
                                onReroute: () =>
                                    _onRerouteToDockPressed(context, viewModel),
                                onClose: viewModel.clearSelectedStation,
                              )
                            : viewModel.showEmptyStationRerouteAlert
                            ? StationRerouteAlert(
                                selectedStation: selectedStation,
                                suggestedStation:
                                    viewModel.suggestedAlternativeBikeStation,
                                onReroute: () =>
                                    _onRerouteToBikePressed(context, viewModel),
                                onClose: viewModel.clearSelectedStation,
                                title: 'No Bikes Available',
                                description:
                                    'Your selected station ${selectedStation.name} has no available bikes.',
                                noSuggestionMessage:
                                    'No nearby station with bikes found.',
                                suggestionLabelBuilder: (Station station) =>
                                    '${station.availableBikes} bikes ready',
                                rerouteButtonText: 'Reroute to Available Bike',
                              )
                            : StationInfoPopup(
                                station: selectedStation,
                                isReturnMode: viewModel.isReturnMode,
                                onClose: viewModel.clearSelectedStation,
                                onNavigate: () => _onNavigateHerePressed(
                                  context,
                                  viewModel,
                                  selectedStation,
                                ),
                                onReturnBike: () => _onReturnBikePressed(
                                  context,
                                  viewModel,
                                  selectedStation,
                                ),
                                onViewBikes: () => _onViewBikesPressed(
                                  context,
                                  selectedStation,
                                ),
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
                onScanTap: viewModel.hasActiveRide
                    ? null
                    : () => _onScanButtonPressed(context, viewModel),
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
