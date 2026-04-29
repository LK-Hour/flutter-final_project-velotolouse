import 'package:final_project_velotolouse/app.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/services/ride_service.dart';
import 'package:final_project_velotolouse/services/station_service.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:final_project_velotolouse/ui/states/ride_state.dart';
import 'package:final_project_velotolouse/ui/states/station_state.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Entry point shared by all environments.
///
/// Two-stage provider setup (matching the BlaBla architecture pattern):
///   Stage 1 — Repositories + Services    provided in [main_dev.dart]
///   Stage 2 — Global States + ViewModels provided in [VeloToulouseAppWrapper]
///             (needs context to read Stage-1 providers)
void mainCommon(List<SingleChildWidget> providers) {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => MultiProvider(
        providers: providers,
        child: const VeloToulouseAppWrapper(),
      ),
    ),
  );
}

/// Sets up Layer 3 (global states) and Layer 4 (view models) after the
/// repository / service providers from [main_dev.dart] are available.
class VeloToulouseAppWrapper extends StatelessWidget {
  const VeloToulouseAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Layer 3: Global States ───────────────────────────────────────
        ChangeNotifierProvider<RideState>(
          create: (context) => RideState(context.read<RideRepository>()),
        ),
        ChangeNotifierProvider<StationState>(
          create: (context) => StationState(
            repository: context.read<StationRepository>(),
            userLocationRepository: context.read<UserLocationRepository>(),
          )..loadStations(),
        ),

        // ── Layer 4: ViewModels (read States + Services via context) ─────
        ChangeNotifierProvider<StationMapViewModel>(
          create: (context) => StationMapViewModel(
            rideState: context.read<RideState>(),
            stationState: context.read<StationState>(),
            stationService: context.read<StationService>(),
            rideService: context.read<RideService>(),
            bikeRepository: context.read<BikeRepository>(),
            navigationLauncherRepository:
                context.read<NavigationLauncherRepository>(),
            stationRouteRepository: context.read<StationRouteRepository>(),
            userLocationRepository: context.read<UserLocationRepository>(),
          ),
        ),
      ],
      child: const VeloToulouseApp(),
    );
  }
}
