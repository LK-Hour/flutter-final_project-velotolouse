import 'dart:math' as math;

import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_marker.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlng;

class StationGoogleMapCanvas extends StatefulWidget {
  const StationGoogleMapCanvas({
    super.key,
    required this.stations,
    required this.isReturnMode,
    required this.selectedStation,
    required this.mapCenter,
    required this.currentUserLocation,
    required this.routePath,
    required this.locateRequestVersion,
    required this.onStationTap,
    required this.onMapTap,
    required this.fallbackMarkerPositions,
  });

  final List<Station> stations;
  final bool isReturnMode;
  final Station? selectedStation;
  final GeoCoordinate mapCenter;
  final GeoCoordinate? currentUserLocation;
  final List<GeoCoordinate> routePath;
  final int locateRequestVersion;
  final ValueChanged<String> onStationTap;
  final VoidCallback onMapTap;
  final Map<String, Offset> fallbackMarkerPositions;
  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const double _averageBikeSpeedKmh = 15.0;

  @override
  State<StationGoogleMapCanvas> createState() => _StationGoogleMapCanvasState();
}

class _StationGoogleMapCanvasState extends State<StationGoogleMapCanvas> {
  gmaps.GoogleMapController? _googleMapController;
  final fmap.MapController _tileMapController = fmap.MapController();
  bool _isTileMapReady = false;

  @override
  void didUpdateWidget(covariant StationGoogleMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool hasMapCenterChanged = _hasMapCenterChanged(
      oldWidget.mapCenter,
      widget.mapCenter,
    );
    final bool hasLocateRequestChanged =
        oldWidget.locateRequestVersion != widget.locateRequestVersion;

    if (!hasMapCenterChanged && !hasLocateRequestChanged) {
      return;
    }
    _moveMapViewToCenter(animated: true);
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWidgetTestEnvironment) {
      return _buildFallbackCanvas();
    }

    if (_supportsNativeGoogleMap) {
      return _buildGoogleMap();
    }

    if (_supportsTileMapFallback) {
      return _buildTileMapFallback();
    }

    return _buildFallbackCanvas();
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      key: const ValueKey<String>('google-map-canvas'),
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(
          widget.mapCenter.latitude,
          widget.mapCenter.longitude,
        ),
        zoom: 13.2,
      ),
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      mapType: gmaps.MapType.normal,
      onMapCreated: (gmaps.GoogleMapController controller) {
        _googleMapController = controller;
        _moveMapViewToCenter();
      },
      onTap: (_) => widget.onMapTap(),
      markers: _buildGoogleMarkers(),
      polylines: _buildGoogleRoutePolylines(),
    );
  }

  Widget _buildTileMapFallback() {
    final latlng.LatLng currentCenter = latlng.LatLng(
      widget.mapCenter.latitude,
      widget.mapCenter.longitude,
    );

    return fmap.FlutterMap(
      key: const ValueKey<String>('tile-map-canvas'),
      mapController: _tileMapController,
      options: fmap.MapOptions(
        initialCenter: currentCenter,
        initialZoom: 13.2,
        onMapReady: () {
          _isTileMapReady = true;
          _moveMapViewToCenter();
        },
        onTap: (_, _) => widget.onMapTap(),
      ),
      children: <Widget>[
        fmap.TileLayer(
          urlTemplate: StationGoogleMapCanvas._osmTileUrl,
          userAgentPackageName: 'com.cadt.velotoulouse',
        ),
        fmap.MarkerLayer(markers: _buildTileMapMarkers()),
        fmap.PolylineLayer(polylines: _buildTileRoutePolylines()),
      ],
    );
  }

  Widget _buildFallbackCanvas() {
    return GestureDetector(
      key: const Key('fallback-map-canvas'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onMapTap,
      child: Container(
        color: AppColors.mapBackground,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              children: <Widget>[
                for (final Station station in widget.stations)
                  () {
                    final bool isSelected =
                        widget.selectedStation?.id == station.id;
                    final bool isAvailable = _hasAvailability(station);
                    return StationMarkerWidget(
                      key: Key('station-marker-${station.id}'),
                      label: _markerLabel(station),
                      etaLabel: _etaLabel(
                        isSelected: isSelected,
                        isAvailable: isAvailable,
                      ),
                      isAvailableInCurrentMode: isAvailable,
                      isReturnMode: widget.isReturnMode,
                      isSelected: isSelected,
                      mapPosition:
                          widget.fallbackMarkerPositions[station.id] ??
                          const Offset(0.5, 0.5),
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      onTap: () => widget.onStationTap(station.id),
                    );
                  }(),
                if (widget.currentUserLocation != null)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        child: _CurrentLocationMarker(
                          markerKey: Key('current-location-fallback-marker'),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _supportsNativeGoogleMap {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _supportsTileMapFallback {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get _isWidgetTestEnvironment {
    final WidgetsBinding binding = WidgetsBinding.instance;
    final String typeName = binding.runtimeType.toString();
    return typeName.contains('TestWidgetsFlutterBinding');
  }

  Set<gmaps.Marker> _buildGoogleMarkers() {
    final Set<gmaps.Marker> markers = widget.stations.map((Station station) {
      final bool isSelected = widget.selectedStation?.id == station.id;
      final bool isAvailable = _hasAvailability(station);
      final String snippet = _markerLabel(station);

      return gmaps.Marker(
        markerId: gmaps.MarkerId(station.id),
        position: gmaps.LatLng(station.latitude, station.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          _markerHue(
            isSelected: isSelected,
            isAvailable: isAvailable,
            isReturnMode: widget.isReturnMode,
          ),
        ),
        infoWindow: gmaps.InfoWindow(title: station.name, snippet: snippet),
        onTap: () => widget.onStationTap(station.id),
      );
    }).toSet();

    if (widget.currentUserLocation != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('current-user-location'),
          position: gmaps.LatLng(
            widget.currentUserLocation!.latitude,
            widget.currentUserLocation!.longitude,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'You are here'),
        ),
      );
    }

    return markers;
  }

  Set<gmaps.Polyline> _buildGoogleRoutePolylines() {
    if (widget.routePath.length < 2) {
      return <gmaps.Polyline>{};
    }

    return <gmaps.Polyline>{
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('station-route'),
        color: AppColors.warning,
        width: 5,
        geodesic: true,
        points: widget.routePath
            .map(
              (GeoCoordinate point) =>
                  gmaps.LatLng(point.latitude, point.longitude),
            )
            .toList(growable: false),
      ),
    };
  }

  List<fmap.Marker> _buildTileMapMarkers() {
    final List<fmap.Marker> markers = widget.stations.map((Station station) {
      final bool isSelected = widget.selectedStation?.id == station.id;
      final bool isAvailable = _hasAvailability(station);
      final String label = _markerLabel(station);
      final String? etaLabel = _etaLabel(
        isSelected: isSelected,
        isAvailable: isAvailable,
      );

      return fmap.Marker(
        key: Key('linux-station-marker-${station.id}'),
        point: latlng.LatLng(station.latitude, station.longitude),
        width: widget.isReturnMode ? 134 : 86,
        height: widget.isReturnMode ? (etaLabel == null ? 72 : 88) : 76,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onStationTap(station.id),
          child: Align(
            alignment: Alignment.topCenter,
            child: StationMarkerVisual(
              label: label,
              etaLabel: etaLabel,
              isSelected: isSelected,
              isAvailableInCurrentMode: isAvailable,
              isReturnMode: widget.isReturnMode,
            ),
          ),
        ),
      );
    }).toList();

    if (widget.currentUserLocation != null) {
      markers.add(
        fmap.Marker(
          key: const Key('current-location-tile-marker'),
          point: latlng.LatLng(
            widget.currentUserLocation!.latitude,
            widget.currentUserLocation!.longitude,
          ),
          width: 44,
          height: 44,
          child: const IgnorePointer(child: _CurrentLocationMarker()),
        ),
      );
    }

    return markers;
  }

  List<fmap.Polyline> _buildTileRoutePolylines() {
    if (widget.routePath.length < 2) {
      return const <fmap.Polyline>[];
    }

    return <fmap.Polyline>[
      fmap.Polyline(
        points: widget.routePath
            .map(
              (GeoCoordinate point) =>
                  latlng.LatLng(point.latitude, point.longitude),
            )
            .toList(growable: false),
        strokeWidth: 5,
        color: AppColors.warning,
      ),
    ];
  }

  bool _hasAvailability(Station station) {
    return widget.isReturnMode
        ? station.freeDocks > 0
        : station.availableBikes > 0;
  }

  String _markerLabel(Station station) {
    if (!widget.isReturnMode) {
      return '${station.availableBikes} Bikes';
    }

    if (station.freeDocks == 0) {
      return 'P | Full';
    }

    return 'P | ${station.freeDocks} Free';
  }

  String? _etaLabel({required bool isSelected, required bool isAvailable}) {
    if (!widget.isReturnMode || !isSelected || !isAvailable) {
      return null;
    }

    if (widget.currentUserLocation == null ||
        widget.selectedStation == null) {
      return null;
    }

    final int minutes = _calculateEtaMinutes(
      widget.currentUserLocation!,
      widget.selectedStation!,
    );

    return '$minutes min away';
  }

  int _calculateEtaMinutes(GeoCoordinate userLocation, Station station) {
    final double distanceKm = _calculateDistanceKm(
      userLocation.latitude,
      userLocation.longitude,
      station.latitude,
      station.longitude,
    );

    final double timeHours = distanceKm / StationGoogleMapCanvas._averageBikeSpeedKmh;
    final int timeMinutes = (timeHours * 60).ceil();

    return math.max(1, timeMinutes);
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  bool _hasMapCenterChanged(GeoCoordinate oldValue, GeoCoordinate newValue) {
    return oldValue.latitude != newValue.latitude ||
        oldValue.longitude != newValue.longitude;
  }

  void _moveMapViewToCenter({bool animated = false}) {
    if (_isWidgetTestEnvironment) {
      return;
    }

    if (_supportsNativeGoogleMap) {
      final gmaps.GoogleMapController? controller = _googleMapController;
      if (controller == null) {
        return;
      }

      final gmaps.CameraUpdate cameraUpdate = gmaps.CameraUpdate.newLatLng(
        gmaps.LatLng(widget.mapCenter.latitude, widget.mapCenter.longitude),
      );
      if (animated) {
        controller.animateCamera(cameraUpdate);
      } else {
        controller.moveCamera(cameraUpdate);
      }
      return;
    }

    if (_supportsTileMapFallback) {
      if (!_isTileMapReady) {
        return;
      }
      final latlng.LatLng targetCenter = latlng.LatLng(
        widget.mapCenter.latitude,
        widget.mapCenter.longitude,
      );
      _tileMapController.move(targetCenter, _tileMapController.camera.zoom);
    }
  }

  double _markerHue({
    required bool isSelected,
    required bool isAvailable,
    required bool isReturnMode,
  }) {
    if (isSelected) {
      return gmaps.BitmapDescriptor.hueAzure;
    }
    if (!isAvailable) {
      return gmaps.BitmapDescriptor.hueRed;
    }
    return isReturnMode
        ? gmaps.BitmapDescriptor.hueGreen
        : gmaps.BitmapDescriptor.hueOrange;
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker({this.markerKey});

  final Key? markerKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: markerKey,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.my_location_rounded,
        size: 16,
        color: AppColors.success,
      ),
    );
  }
}
