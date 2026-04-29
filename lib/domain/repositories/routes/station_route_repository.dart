import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';

abstract class StationRouteRepository {
  Future<List<GeoCoordinate>> fetchCyclingRoute({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  });
}
