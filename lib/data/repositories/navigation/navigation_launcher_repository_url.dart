import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/repositories/navigation/navigation_launcher_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlNavigationLauncherRepository implements NavigationLauncherRepository {
  @override
  Future<bool> openDirections({
    GeoCoordinate? origin,
    required GeoCoordinate destination,
  }) async {
    final String destinationParam =
        '${destination.latitude},${destination.longitude}';
    final Uri uri = Uri.parse(
      origin == null
          ? 'https://www.google.com/maps/dir/?api=1'
                '&destination=$destinationParam'
                '&travelmode=bicycling'
          : 'https://www.google.com/maps/dir/?api=1'
                '&origin=${origin.latitude},${origin.longitude}'
                '&destination=$destinationParam'
                '&travelmode=bicycling',
    );

    final LaunchMode mode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;

    try {
      return await launchUrl(uri, mode: mode);
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on UnsupportedError {
      return false;
    }
  }
}
