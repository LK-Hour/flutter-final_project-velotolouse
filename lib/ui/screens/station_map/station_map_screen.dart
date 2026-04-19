import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/bottom_ride_panel.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/map_quick_actions.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/search_controls.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_google_map_canvas.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_info_popup.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_reroute_alert.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_search_sheet.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StationMapScreen extends StatelessWidget {
  const StationMapScreen({super.key});

  static const Map<String, Offset> _markerMapPosition = <String, Offset>{
    'capitole-square': Offset(0.34, 0.24),
    'jean-jaures': Offset(0.24, 0.55),
    'carmes': Offset(0.64, 0.52),
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

  void _onScanButtonPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR scan is coming soon.')));
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

  void _onNavigateHerePressed(BuildContext context, Station station) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigating to ${station.name}...')));
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
                          locateRequestVersion: viewModel.locateRequestVersion,
                          fallbackMarkerPositions: _markerMapPosition,
                          onStationTap: viewModel.selectStation,
                        ),
                      ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 12,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: StationMapSearchField(
                              onTap: () => _onSearchTapped(context, viewModel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          StationMapModeButton(
                            isReturnMode: viewModel.isReturnMode,
                            onTap: () => _onTopRightButtonTapped(context),
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
                    const Positioned(
                      right: 48,
                      bottom: 150,
                      child: StationMapPinDot(),
                    ),
                    if (selectedStation != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 122,
                        child: viewModel.showFullStationRerouteAlert
                            ? StationRerouteAlert(
                                selectedStation: selectedStation,
                                suggestedStation:
                                    viewModel.suggestedAlternativeDockStation,
                                onReroute: viewModel.rerouteToSuggestedDock,
                                onClose: viewModel.clearSelectedStation,
                              )
                            : StationInfoPopup(
                                station: selectedStation,
                                isReturnMode: viewModel.isReturnMode,
                                onClose: viewModel.clearSelectedStation,
                                onNavigate: () => _onNavigateHerePressed(
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
                onScanTap: () => _onScanButtonPressed(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
