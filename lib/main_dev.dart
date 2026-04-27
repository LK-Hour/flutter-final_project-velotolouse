import 'package:final_project_velotolouse/data/repositories/bikes/mock_bike_repository.dart';
import 'package:final_project_velotolouse/data/repositories/location/user_location_repository_device.dart';
import 'package:final_project_velotolouse/data/repositories/rides/mock_ride_repository.dart';
import 'package:final_project_velotolouse/data/repositories/stations/station_repository_mock.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/main_common.dart';
import 'package:final_project_velotolouse/services/ride_service.dart';
import 'package:final_project_velotolouse/services/station_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Development providers configuration using mock repositories.
/// 
/// Architecture layers (bottom-up):
/// 1. Repositories (data layer) - abstract classes with mock implementations
/// 2. Services (business logic) - stateless logic processors
/// 3. Global States (managed in main_common.dart) - app-wide state
/// 4. ViewModels (screen-level) - coordinate between states and UI
List<SingleChildWidget> get devProviders {
  return <SingleChildWidget>[
    // Layer 1: Repositories (data access layer)
    Provider<UserLocationRepository>(
      create: (_) => DeviceUserLocationRepository(),
    ),
    Provider<StationRepository>(
      create: (_) => MockStationRepository(),
    ),
    Provider<BikeRepository>(
      create: (_) => MockBikeRepository(),
    ),
    Provider<RideRepository>(
      create: (_) => MockRideRepository(),
    ),

    // Layer 2: Services (business logic layer)
    Provider<StationService>(
      create: (_) => StationService(),
    ),
    Provider<RideService>(
      create: (_) => RideService(),
    ),
  ];
}

void main() {
  mainCommon(devProviders);
}

