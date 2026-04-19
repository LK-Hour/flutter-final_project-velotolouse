import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';

enum UserLocationStatus {
  located,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class UserLocationResult {
  const UserLocationResult({
    required this.status,
    this.coordinate,
  });

  final UserLocationStatus status;
  final GeoCoordinate? coordinate;
}
