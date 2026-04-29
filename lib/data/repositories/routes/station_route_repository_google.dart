import 'dart:convert';

import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/repositories/routes/station_route_repository.dart';
import 'package:http/http.dart' as http;

class GoogleStationRouteRepository implements StationRouteRepository {
  GoogleStationRouteRepository({required String apiKey, http.Client? client})
    : _apiKey = apiKey,
      _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  @override
  Future<List<GeoCoordinate>> fetchCyclingRoute({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  }) async {
    if (_apiKey.trim().isEmpty) {
      return _fetchFromOsrm(origin: origin, destination: destination);
    }

    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      <String, String>{
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'bicycling',
        'key': _apiKey,
      },
    );

    try {
      final http.Response response = await _client.get(uri);
      if (response.statusCode != 200) {
        return _fetchFromOsrm(origin: origin, destination: destination);
      }

      final dynamic jsonBody = jsonDecode(response.body);
      if (jsonBody is! Map<String, dynamic>) {
        return _fetchFromOsrm(origin: origin, destination: destination);
      }
      if (jsonBody['status'] != 'OK') {
        return _fetchFromOsrm(origin: origin, destination: destination);
      }

      final List<dynamic>? routes = jsonBody['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return _fetchFromOsrm(origin: origin, destination: destination);
      }

      final Map<String, dynamic>? route = routes.first as Map<String, dynamic>?;
      if (route == null) {
        return _fetchFromOsrm(origin: origin, destination: destination);
      }

      final Map<String, dynamic>? overviewPolyline =
          route['overview_polyline'] as Map<String, dynamic>?;
      final String? encodedPolyline = overviewPolyline?['points'] as String?;
      if (encodedPolyline == null || encodedPolyline.isEmpty) {
        return _fetchFromOsrm(origin: origin, destination: destination);
      }

      return _decodePolyline(encodedPolyline);
    } on Exception {
      return _fetchFromOsrm(origin: origin, destination: destination);
    }
  }

  Future<List<GeoCoordinate>> _fetchFromOsrm({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  }) async {
    final Uri uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/bicycle/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
      <String, String>{'overview': 'full', 'geometries': 'geojson'},
    );

    try {
      final http.Response response = await _client.get(uri);
      if (response.statusCode != 200) {
        return const <GeoCoordinate>[];
      }

      final dynamic jsonBody = jsonDecode(response.body);
      if (jsonBody is! Map<String, dynamic>) {
        return const <GeoCoordinate>[];
      }
      if (jsonBody['code'] != 'Ok') {
        return const <GeoCoordinate>[];
      }

      final List<dynamic>? routes = jsonBody['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return const <GeoCoordinate>[];
      }

      final Map<String, dynamic>? route = routes.first as Map<String, dynamic>?;
      if (route == null) {
        return const <GeoCoordinate>[];
      }
      final Map<String, dynamic>? geometry =
          route['geometry'] as Map<String, dynamic>?;
      final List<dynamic>? coordinates =
          geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        return const <GeoCoordinate>[];
      }

      final List<GeoCoordinate> points = coordinates
          .whereType<List<dynamic>>()
          .where((List<dynamic> point) => point.length >= 2)
          .map((List<dynamic> point) {
            final dynamic longitudeValue = point[0];
            final dynamic latitudeValue = point[1];
            if (longitudeValue is! num || latitudeValue is! num) {
              return const GeoCoordinate(latitude: 0, longitude: 0);
            }
            return GeoCoordinate(
              latitude: latitudeValue.toDouble(),
              longitude: longitudeValue.toDouble(),
            );
          })
          .where(
            (GeoCoordinate point) =>
                point.latitude.abs() <= 90 &&
                point.longitude.abs() <= 180 &&
                !(point.latitude == 0 && point.longitude == 0),
          )
          .toList(growable: false);

      return points;
    } on Exception {
      return const <GeoCoordinate>[];
    }
  }

  List<GeoCoordinate> _decodePolyline(String encoded) {
    final List<GeoCoordinate> points = <GeoCoordinate>[];
    int index = 0;
    int latitude = 0;
    int longitude = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;
      do {
        if (index >= encoded.length) {
          return points;
        }
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final int latitudeDelta = (result & 1) != 0
          ? ~(result >> 1)
          : (result >> 1);
      latitude += latitudeDelta;

      result = 0;
      shift = 0;
      do {
        if (index >= encoded.length) {
          return points;
        }
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final int longitudeDelta = (result & 1) != 0
          ? ~(result >> 1)
          : (result >> 1);
      longitude += longitudeDelta;

      points.add(
        GeoCoordinate(latitude: latitude / 1e5, longitude: longitude / 1e5),
      );
    }

    return points;
  }
}
