import 'package:final_project_velotolouse/domain/model/stations/station_bike_inventory_item.dart';

abstract class StationBikeInventoryRepository {
  Future<List<StationBikeInventoryItem>> fetchBikesForStation(String stationId);
}
