import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_marker.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlng;

class StationGoogleMapCanvas extends StatelessWidget {
  const StationGoogleMapCanvas({
    super.key,
    required this.stations,
    required this.isReturnMode,
    required this.selectedStation,
    required this.onStationTap,
    required this.fallbackMarkerPositions,
  });

  final List<Station> stations;
  final bool isReturnMode;
  final Station? selectedStation;
  final ValueChanged<String> onStationTap;
  final Map<String, Offset> fallbackMarkerPositions;
  static const latlng.LatLng _mapCenter = latlng.LatLng(43.6046, 1.4442);
  static const String _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
      initialCameraPosition: const gmaps.CameraPosition(
        target: gmaps.LatLng(43.6046, 1.4442),
        zoom: 13.2,
      ),
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      markers: _buildGoogleMarkers(),
    );
  }

  Widget _buildTileMapFallback() {
    return fmap.FlutterMap(
      options: const fmap.MapOptions(
        initialCenter: _mapCenter,
        initialZoom: 13.2,
      ),
      children: <Widget>[
        fmap.TileLayer(
          urlTemplate: _osmTileUrl,
          userAgentPackageName: 'com.cadt.velotoulouse',
        ),
        fmap.MarkerLayer(markers: _buildTileMapMarkers()),
      ],
    );
  }

  Widget _buildFallbackCanvas() {
    return Container(
      color: AppColors.mapBackground,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: <Widget>[
              for (final Station station in stations)
                StationMarkerWidget(
                  key: Key('station-marker-${station.id}'),
                  label: isReturnMode
                      ? '${station.freeDocks} Docks'
                      : '${station.availableBikes} Bikes',
                  isAvailableInCurrentMode: isReturnMode
                      ? station.freeDocks > 0
                      : station.availableBikes > 0,
                  isReturnMode: isReturnMode,
                  isSelected: selectedStation?.id == station.id,
                  mapPosition:
                      fallbackMarkerPositions[station.id] ??
                      const Offset(0.5, 0.5),
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  onTap: () => onStationTap(station.id),
                ),
            ],
          );
        },
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
    return stations.map((Station station) {
      final bool isSelected = selectedStation?.id == station.id;
      final bool isAvailable = isReturnMode
          ? station.freeDocks > 0
          : station.availableBikes > 0;
      final String snippet = isReturnMode
          ? '${station.freeDocks} Docks'
          : '${station.availableBikes} Bikes';

      return gmaps.Marker(
        markerId: gmaps.MarkerId(station.id),
        position: gmaps.LatLng(station.latitude, station.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          _markerHue(
            isSelected: isSelected,
            isAvailable: isAvailable,
            isReturnMode: isReturnMode,
          ),
        ),
        infoWindow: gmaps.InfoWindow(title: station.name, snippet: snippet),
        onTap: () => onStationTap(station.id),
      );
    }).toSet();
  }

  List<fmap.Marker> _buildTileMapMarkers() {
    return stations.map((Station station) {
      final bool isSelected = selectedStation?.id == station.id;
      final bool isAvailable = isReturnMode
          ? station.freeDocks > 0
          : station.availableBikes > 0;
      final String label = isReturnMode
          ? '${station.freeDocks} Docks'
          : '${station.availableBikes} Bikes';

      return fmap.Marker(
        key: Key('linux-station-marker-${station.id}'),
        point: latlng.LatLng(station.latitude, station.longitude),
        width: 118,
        height: 58,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onStationTap(station.id),
          child: _LinuxStationMarker(
            label: label,
            isSelected: isSelected,
            isAvailable: isAvailable,
            isReturnMode: isReturnMode,
          ),
        ),
      );
    }).toList();
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

class _LinuxStationMarker extends StatelessWidget {
  const _LinuxStationMarker({
    required this.label,
    required this.isSelected,
    required this.isAvailable,
    required this.isReturnMode,
  });

  final String label;
  final bool isSelected;
  final bool isAvailable;
  final bool isReturnMode;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    if (isSelected) {
      backgroundColor = AppColors.slate;
    } else if (!isAvailable) {
      backgroundColor = AppColors.neutralText;
    } else {
      backgroundColor = isReturnMode ? AppColors.success : AppColors.warning;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
