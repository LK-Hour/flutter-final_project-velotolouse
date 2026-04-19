import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/bottom_ride_panel.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/map_quick_actions.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/search_controls.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_info_popup.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_marker.dart';
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

  void _onSearchTapped(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search is coming soon.')));
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
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 12,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: StationMapSearchField(
                              onTap: () => _onSearchTapped(context),
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
                    if (viewModel.isReturnMode)
                      const Positioned(
                        left: 16,
                        top: 72,
                        child: _ReturnModeBadge(),
                      ),
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
                        child: LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                return Stack(
                                  children: <Widget>[
                                    for (final Station station
                                        in viewModel.stations)
                                      StationMarkerWidget(
                                        key: Key(
                                          'station-marker-${station.id}',
                                        ),
                                        label: viewModel
                                            .availabilityLabelForCurrentMode(
                                              station,
                                            ),
                                        isAvailableInCurrentMode: viewModel
                                            .hasAvailabilityForCurrentMode(
                                              station,
                                            ),
                                        isReturnMode: viewModel.isReturnMode,
                                        isSelected:
                                            station.id == selectedStation?.id,
                                        mapPosition:
                                            _markerMapPosition[station.id] ??
                                            const Offset(0.5, 0.5),
                                        width: constraints.maxWidth,
                                        height: constraints.maxHeight,
                                        onTap: () =>
                                            viewModel.selectStation(station.id),
                                      ),
                                  ],
                                );
                              },
                        ),
                      ),
                    const Positioned(
                      right: 14,
                      top: 210,
                      child: StationMapQuickActions(),
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
                        child: StationInfoPopup(
                          station: selectedStation,
                          isReturnMode: viewModel.isReturnMode,
                          onClose: viewModel.clearSelectedStation,
                          onNavigate: () =>
                              _onNavigateHerePressed(context, selectedStation),
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

class _ReturnModeBadge extends StatelessWidget {
  const _ReturnModeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1A11B982),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
          SizedBox(width: 6),
          Text(
            'SMART RETURN MODE ACTIVE',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
