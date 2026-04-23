import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../domain/model/stations/station.dart';
import '../themes/theme.dart';
import 'qr_scanner_screen.dart';

/// Station View Screen with Google Maps and draggable bike slots list
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key, this.station, this.allStations});

  final Station? station;
  final List<Station>? allStations;

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  // Capitole Square coordinates (Toulouse, France)
  late LatLng _stationLocation;
  late Station? currentStation;
  int currentStationIndex = 0;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    currentStation = widget.station;
    // Find current station index if allStations is provided
    if (widget.allStations != null && widget.station != null) {
      currentStationIndex = widget.allStations!.indexWhere((s) => s.id == widget.station!.id);
      if (currentStationIndex == -1) currentStationIndex = 0;
    }
    // Use passed station location or default to Capitole Square
    _stationLocation = currentStation != null
        ? LatLng(currentStation!.latitude, currentStation!.longitude)
        : const LatLng(43.6047, 1.4442);
  }

  // Sheet drag state
  double _sheetHeight = 310;
  static const double _minHeight = 180;
  static const double _maxHeight = 600;
  static const double _snapLow = 310;
  static const double _snapHigh = 570;

  // Station data with dock info
  final List<Map<String, dynamic>> _stations = [
    {
      'label': 'P 12',
      'name': 'Capitole Square',
      'address': 'Place du Capitole, 31000 Toulouse',
      'freeDocks': 12,
      'totalCapacity': 20,
      'distance': '450m away',
      'lat': 43.6057,
      'lng': 1.4452,
      'color': Colors.orange,
    },
    {
      'label': 'P 8',
      'name': 'Wilson Square',
      'address': 'Place Wilson, 31000 Toulouse',
      'freeDocks': 8,
      'totalCapacity': 15,
      'distance': '820m away',
      'lat': 43.6037,
      'lng': 1.4432,
      'color': Colors.red,
    },
    {
      'label': 'P 4',
      'name': 'Saint-Sernin',
      'address': 'Place Saint-Sernin, 31000 Toulouse',
      'freeDocks': 4,
      'totalCapacity': 10,
      'distance': '1.1km away',
      'lat': 43.6047,
      'lng': 1.4480,
      'color': Colors.red,
    },
  ];

  void _onStationTapped(Map<String, dynamic> station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _StationPopup(station: station),
    );
  }

  void _switchToPreviousStation() {
    if (widget.allStations == null || widget.allStations!.isEmpty) return;
    setState(() {
      currentStationIndex = (currentStationIndex - 1) % widget.allStations!.length;
      if (currentStationIndex < 0) currentStationIndex = widget.allStations!.length - 1;
      currentStation = widget.allStations![currentStationIndex];
      _stationLocation = LatLng(currentStation!.latitude, currentStation!.longitude);
      _mapController.move(_stationLocation, 15.5);
    });
  }

  void _switchToNextStation() {
    if (widget.allStations == null || widget.allStations!.isEmpty) return;
    setState(() {
      currentStationIndex = (currentStationIndex + 1) % widget.allStations!.length;
      currentStation = widget.allStations![currentStationIndex];
      _stationLocation = LatLng(currentStation!.latitude, currentStation!.longitude);
      _mapController.move(_stationLocation, 15.5);
    });
  }

  // Generate bike slots based on station data
  List<bool> _generateBikeSlots() {
    final totalCapacity = currentStation?.totalCapacity ?? 20;
    final availableBikes = currentStation?.availableBikes ?? 5;
    
    // Create a list representing all slots
    List<bool> slots = List.filled(totalCapacity, false);
    
    // Use station ID hash as seed for consistent "randomness" per station
    final seed = currentStation?.id.hashCode ?? 0;
    final random = seed.abs();
    
    // Distribute available bikes across slots
    for (int i = 0; i < availableBikes && i < totalCapacity; i++) {
      // Use a pattern based on the seed to determine which slots have bikes
      int slotIndex = (i * 3 + random) % totalCapacity;
      slots[slotIndex] = true;
    }
    
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bottom layer: OpenStreetMap (no API key needed)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _stationLocation,
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.velotoulouse.app',
              ),
              MarkerLayer(
                markers: _stations.map((station) {
                  return Marker(
                    point: LatLng(station['lat'], station['lng']),
                    width: 60,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _onStationTapped(station),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: station['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            station['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          // Top app bar with status
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ride status
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            'Ride in Progress: 14:02',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Previous/Next station buttons or Plus button
                    if (widget.allStations != null && widget.allStations!.length > 1) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, size: 24),
                          onPressed: _switchToPreviousStation,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, size: 24),
                          onPressed: _switchToNextStation,
                        ),
                      ),
                    ] else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom sheet with bike slots
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _sheetHeight = (_sheetHeight - details.delta.dy)
                      .clamp(_minHeight, _maxHeight);
                });
              },
              onVerticalDragEnd: (details) {
                // Snap to nearest position
                final mid1 = (_minHeight + _snapLow) / 2;
                final mid2 = (_snapLow + _snapHigh) / 2;
                final mid3 = (_snapHigh + _maxHeight) / 2;
                double target;
                if (_sheetHeight < mid1) {
                  target = _minHeight;
                } else if (_sheetHeight < mid2) {
                  target = _snapLow;
                } else if (_sheetHeight < mid3) {
                  target = _snapHigh;
                } else {
                  target = _maxHeight;
                }
                setState(() => _sheetHeight = target);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: _sheetHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: SingleChildScrollView(
                  physics: _sheetHeight >= _maxHeight
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: _buildSheetContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent() {
    final isMinimized = _sheetHeight <= _minHeight + 20;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Minimized state: "Ready to ride?" header
          if (isMinimized) ...[
            const Text(
              'Ready to ride?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 110), // Extra padding for nav bar
          ] else ...[
            // Expanded state: Full station details
            // Smart return mode indicator
            Row(
              children: [
                Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'SMART RETURN MODE ACTIVE',
                style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Station name and distance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentStation?.name ?? 'Capitole Square', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(currentStation?.address ?? 'Place du Capitole, 31000 Toulouse', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              Text('450m away', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),

          // Stats boxes
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${currentStation?.freeDocks ?? 12}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                      Text('Free Docks', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${currentStation?.totalCapacity ?? 20}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                      Text('Total Capacity', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bike Slots header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bike Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${currentStation?.totalCapacity ?? 20} slots total', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),

          // Bike slots - dynamically generated
          ...() {
            final slots = _generateBikeSlots();
            final slotsToShow = slots.take(5).toList();
            return List.generate(slotsToShow.length, (index) {
              final showBikeButton = index == 1 && slotsToShow[index];
              return _BikeSlotItem(
                slotNumber: index + 1,
                isAvailable: slotsToShow[index],
                showBikeButton: showBikeButton,
              );
            });
          }(),

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text('+ ${(currentStation?.totalCapacity ?? 20) - 5} more slots', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ),
          ),
          const SizedBox(height: 110), // Extra padding for nav bar
          ], // end of expanded content
        ],
      ),
    );
  }
}

/// Popup shown when tapping a station marker on the map
class _StationPopup extends StatelessWidget {
  final Map<String, dynamic> station;

  const _StationPopup({required this.station});

  @override
  Widget build(BuildContext context) {
    final freeDocks = station['freeDocks'] as int;
    final totalCapacity = station['totalCapacity'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: station['color'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    station['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        station['address'] as String,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  station['distance'] as String,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$freeDocks',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        Text('Free Docks', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalCapacity',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Total Capacity', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual bike slot card widget
/// Individual bike slot item widget
class _BikeSlotItem extends StatelessWidget {
  final int slotNumber;
  final bool isAvailable;
  final bool showBikeButton;

  const _BikeSlotItem({
    required this.slotNumber,
    required this.isAvailable,
    this.showBikeButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable 
          ? AppTheme.successGreen.withOpacity(0.05)
          : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Number circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.successGreen : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$slotNumber',
                style: TextStyle(
                  color: isAvailable ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Bike icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAvailable 
                ? AppTheme.successGreen.withOpacity(0.2)
                : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.pedal_bike,
              color: isAvailable ? AppTheme.successGreen : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Status text
          Expanded(
            child: Text(
              isAvailable ? 'Available' : 'Empty slot',
              style: TextStyle(
                color: isAvailable ? AppTheme.successGreen : Colors.grey[500],
                fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          
          // Action buttons or add icon
          if (isAvailable && showBikeButton) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Bike',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isAvailable)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Rent',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.add,
              color: Colors.grey[400],
              size: 24,
            ),
        ],
      ),
    );
  }
}
