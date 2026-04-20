import 'package:final_project_velotolouse/data/repositories/location/user_location_repository_device.dart';
import 'package:final_project_velotolouse/data/repositories/navigation/navigation_launcher_repository_url.dart';
import 'package:final_project_velotolouse/data/repositories/routes/station_route_repository_google.dart';
import 'package:final_project_velotolouse/data/repositories/stations/station_repository_mock.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
import 'package:final_project_velotolouse/main_common.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get devProviders {
  return <SingleChildWidget>[
    Provider<UserLocationRepository>(
      create: (_) => DeviceUserLocationRepository(),
    ),
    Provider<NavigationLauncherRepository>(
      create: (_) => UrlNavigationLauncherRepository(),
    ),
    Provider<StationRouteRepository>(
      create: (_) => GoogleStationRouteRepository(
        apiKey: const String.fromEnvironment('GOOGLE_DIRECTIONS_API_KEY'),
      ),
    ),
    Provider<StationRepository>(create: (_) => MockStationRepository()),
    ChangeNotifierProvider<StationMapViewModel>(
      create: (context) => StationMapViewModel(
        repository: context.read<StationRepository>(),
        userLocationRepository: context.read<UserLocationRepository>(),
        navigationLauncherRepository: context
            .read<NavigationLauncherRepository>(),
        stationRouteRepository: context.read<StationRouteRepository>(),
      )..loadStations(),
    ),
  ];
}

void main() {
  mainCommon(devProviders);
}
