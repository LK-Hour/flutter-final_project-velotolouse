import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class DeviceUserLocationRepository implements UserLocationRepository {
  @override
  Future<UserLocationResult> getCurrentLocation() async {
    try {
      final bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return const UserLocationResult(
          status: UserLocationStatus.serviceDisabled,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const UserLocationResult(
          status: UserLocationStatus.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const UserLocationResult(
          status: UserLocationStatus.permissionDeniedForever,
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      return UserLocationResult(
        status: UserLocationStatus.located,
        coordinate: GeoCoordinate(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on PermissionDeniedException {
      return const UserLocationResult(status: UserLocationStatus.permissionDenied);
    } on LocationServiceDisabledException {
      return const UserLocationResult(status: UserLocationStatus.serviceDisabled);
    } on MissingPluginException {
      return const UserLocationResult(status: UserLocationStatus.unavailable);
    } on UnsupportedError {
      return const UserLocationResult(status: UserLocationStatus.unavailable);
    }
  }
}
