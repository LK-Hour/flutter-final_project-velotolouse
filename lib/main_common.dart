import 'package:final_project_velotolouse/app.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/ui/states/ride_state.dart';
import 'package:final_project_velotolouse/ui/states/station_state.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Main entry point for the app.
/// 
/// Architecture:
/// 1. Repositories & Services are provided at root level (from main_dev.dart)
/// 2. Global States are created here (require MaterialApp context)
/// 3. ViewModels are created at screen level
/// 
/// This follows the BlaBla architecture pattern for clean separation.
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

/// Wrapper widget to set up global states after MaterialApp context.
class VeloToulouseAppWrapper extends StatelessWidget {
  const VeloToulouseAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Layer 3: Global States (require MaterialApp context and repositories)
        ChangeNotifierProvider<RideState>(
          create: (context) => RideState(
            context.read<RideRepository>(),
          ),
        ),
        ChangeNotifierProvider<StationState>(
          create: (context) => StationState(
            repository: context.read<StationRepository>(),
            userLocationRepository: context.read<UserLocationRepository>(),
          )..loadStations(), // Load stations on app start
        ),
      ],
      child: const VeloToulouseApp(),
    );
  }
}

