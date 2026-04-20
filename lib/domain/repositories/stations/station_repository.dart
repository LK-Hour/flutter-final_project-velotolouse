import 'package:final_project_velotolouse/domain/model/stations/station.dart';

abstract class StationRepository {
  Future<List<Station>> fetchStations();
}
