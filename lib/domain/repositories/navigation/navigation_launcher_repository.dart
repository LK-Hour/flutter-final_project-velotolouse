import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';

abstract class NavigationLauncherRepository {
  Future<bool> openDirections({
    GeoCoordinate? origin,
    required GeoCoordinate destination,
  });
}
