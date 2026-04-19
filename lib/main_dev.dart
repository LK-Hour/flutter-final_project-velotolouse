import 'package:final_project_velotolouse/data/repositories/location/user_location_repository_device.dart';
import 'package:final_project_velotolouse/data/repositories/stations/station_repository_mock.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
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
    Provider<StationRepository>(create: (_) => MockStationRepository()),
    ChangeNotifierProvider<StationMapViewModel>(
      create: (context) =>
          StationMapViewModel(
            repository: context.read<StationRepository>(),
            userLocationRepository: context.read<UserLocationRepository>(),
          )
            ..loadStations(),
    ),
  ];
}

void main() {
  mainCommon(devProviders);
}
