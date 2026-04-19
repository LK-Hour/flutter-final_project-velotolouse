import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';

abstract class UserLocationRepository {
  Future<UserLocationResult> getCurrentLocation();
}
