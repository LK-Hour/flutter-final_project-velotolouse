# VeloToulouse Code Explanation Script
## Detailed Code Walkthrough with Explanations

---

## File 1: StationMapViewModel (Business Logic)
**Path:** `lib/ui/screens/station_map/view_model/station_map_view_model.dart`

### Import Statements

```dart
import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
```

The first import brings in the GeoCoordinate class, which is a data structure representing a GPS coordinate with latitude and longitude values. This class is essential for tracking map positions, user locations, and station coordinates throughout the application.

```dart
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
```

This import provides the UserLocationResult class, which encapsulates the result of a location request. It contains both a status enum (located, denied, unavailable, service disabled, etc.) and an optional coordinate value if the location was successfully obtained.

```dart
import 'package:final_project_velotouse/domain/model/stations/station.dart';
```

Here we import the Station model, which represents a bike station in the VeloToulouse system. This model contains all the information about a station including its ID, name, address, available bikes, total capacity, and geographic coordinates.

```dart
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
```

This import brings in the UserLocationRepository interface, which defines the contract for obtaining the user's GPS location. By depending on an interface rather than a concrete implementation, we can easily swap between real GPS providers and mock implementations for testing.

```dart
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';
```

The StationRepository interface is imported here, defining how we fetch station data. This abstraction allows us to use mock data during development and switch to real API calls in production without changing the ViewModel code.

```dart
import 'package:flutter/foundation.dart';
```

This imports Flutter's foundation library, which provides the ChangeNotifier class. ChangeNotifier is the core of our state management system, allowing the ViewModel to notify UI widgets when data changes so they can rebuild with updated information.

### Enum Definition

```dart
enum ReturnBikeResult { success, noActiveRide, stationFull }
```

We define an enum called ReturnBikeResult with three possible values to represent the outcome of a bike return attempt. The "success" value indicates the bike was returned successfully. The "noActiveRide" value is returned when a user tries to return a bike but doesn't have an active ride. Finally, "stationFull" indicates that the selected station has no available docks to accept the bike. Using an enum instead of boolean flags makes the code more readable and type-safe.

### Class Declaration and Constructor

```dart
class StationMapViewModel extends ChangeNotifier {
```

The StationMapViewModel class is declared extending ChangeNotifier, which is Flutter's built-in mechanism for reactive state management. By extending ChangeNotifier, this ViewModel can notify any listening widgets when its state changes. When notifyListeners() is called, all widgets that are watching this ViewModel will automatically rebuild to reflect the updated data.

```dart
  StationMapViewModel({
    required StationRepository repository,
    UserLocationRepository? userLocationRepository,
  }) : _repository = repository,
       _userLocationRepository =
           userLocationRepository ?? const _UnavailableUserLocationRepository();
```

The constructor uses dependency injection to receive its dependencies from the outside rather than creating them internally. The StationRepository is required (indicated by the "required" keyword), meaning it must be provided when creating an instance. The UserLocationRepository is optional (nullable, indicated by the "?" after the type). If no location repository is provided, it defaults to an UnavailableUserLocationRepository implementation. The colon (:) starts the initializer list, where we assign the provided repositories to private instance variables before the constructor body runs. The null-coalescing operator (??) means "use the left side if it's not null, otherwise use the right side."

```dart
  final StationRepository _repository;
  final UserLocationRepository _userLocationRepository;
```

These are private instance variables that store references to the injected repositories. The "final" keyword means they cannot be reassigned after initialization, ensuring that the ViewModel always uses the same repository instances throughout its lifetime. The underscore prefix (_) makes these variables private to this file, following Dart's convention for encapsulation.

```dart
  static const GeoCoordinate defaultMapCenter = GeoCoordinate(
    latitude: 43.6046,
    longitude: 1.4442,
  );
```

This defines a static constant representing the default center point of the map, which is the city center of Toulouse, France. The "static" keyword means this value is shared across all instances of the class rather than being duplicated for each instance. The "const" keyword indicates this is a compile-time constant that never changes, allowing Dart to optimize memory usage. This default center is used when we don't yet have the user's location.

### State Variables

```dart
  bool _isLoading = false;
```

This private boolean tracks whether the ViewModel is currently loading data from the repository. It starts as false, indicating no loading operation is in progress. When set to true, the UI can display a loading spinner to inform users that data is being fetched.

```dart
  String? _errorMessage;
```

This nullable string stores any error message that occurs during data loading. When it's null, there's no error to display. When it contains a string value, the UI can show that error message to the user. The question mark (?) after String makes this a nullable type in Dart's null-safety system.

```dart
  List<Station> _stations = <Station>[];
```

This private list stores all the bike stations that have been fetched from the repository. It's initialized as an empty list using the angle bracket syntax <Station>[] which explicitly specifies the type of elements the list will contain. As stations are loaded, this list is populated with Station objects.

```dart
  Station? _selectedStation;
```

This nullable Station variable tracks which station marker the user has tapped on the map. When null, no station is selected and no info popup is shown. When it contains a Station object, the UI displays detailed information about that station.

```dart
  bool _hasActiveRide = false;
```

This boolean tracks whether the user has checked out a bike and is currently on an active ride. When false, the app is in normal browsing mode showing available bikes. When true, the app switches to "return mode" showing stations with available docks where the user can return their bike.

```dart
  bool _isReturnBannerVisible = true;
```

This boolean controls the visibility of the "Return Mode Active" banner at the top of the map screen. When the user starts a ride, this is set to true to show the banner. The user can dismiss the banner by tapping an X button, which sets this to false, while still remaining in return mode.

```dart
  GeoCoordinate _mapCenter = defaultMapCenter;
```

This variable stores the current center position of the map view. It's initialized to the defaultMapCenter (Toulouse city center) and updates when the user locates themselves or selects a station.

```dart
  GeoCoordinate? _currentUserLocation;
```

This nullable coordinate stores the user's actual GPS position as reported by the device's location services. It starts as null until the user successfully enables location permissions and we receive their coordinates. When not null, a blue marker appears on the map at this position.

```dart
  int _locateRequestVersion = 0;
```

This integer serves as a version counter that increments each time we successfully locate the user. The map widget watches this number, and when it changes, the map smoothly animates its camera to the new location. Without this counter, the map wouldn't know when to trigger the animation.

### Public Getters

```dart
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Station> get stations => List<Station>.unmodifiable(_stations);
  Station? get selectedStation => _selectedStation;
  bool get hasActiveRide => _hasActiveRide;
  bool get isReturnMode => _hasActiveRide;
```

These public getters expose the ViewModel's state to the UI in a controlled way. The arrow syntax (=>) provides a concise way to define simple getters. The "isLoading" getter allows the UI to check if data is currently being fetched. The "errorMessage" getter exposes any error that occurred during loading. The "stations" getter returns an unmodifiable copy of the internal stations list, preventing the UI from accidentally modifying it directly. The "selectedStation" getter provides access to the currently selected station. The "hasActiveRide" and "isReturnMode" getters both return the same value - when the user has an active ride, the app is in return mode, showing stations with available docks instead of available bikes.

```dart
  bool get showReturnModeBanner => isReturnMode && _isReturnBannerVisible;
```

This is a computed property that determines whether the return mode banner should be displayed. It returns true only when both conditions are met: the user must have an active ride (isReturnMode) AND the banner hasn't been dismissed by the user (_isReturnBannerVisible). This allows users to dismiss the banner while staying in return mode, providing a cleaner interface without losing functionality.

```dart
  GeoCoordinate get mapCenter => _mapCenter;
  GeoCoordinate? get currentUserLocation => _currentUserLocation;
  int get locateRequestVersion => _locateRequestVersion;
```

These getters expose location-related state. The mapCenter indicates where the map should be centered, the currentUserLocation provides the user's GPS coordinates for displaying a blue marker, and the locateRequestVersion is a counter that the map widget watches to know when to trigger camera animations.

```dart
  bool get showFullStationRerouteAlert {
    return isReturnMode &&
        _selectedStation != null &&
        _selectedStation!.freeDocks == 0;
  }
```

This computed property determines whether to show a "station full" alert when the user tries to return their bike. It checks three conditions: the user must be in return mode, a station must be selected, and that station must have zero free docks. The exclamation mark (!) is a null-assertion operator that tells Dart we're certain _selectedStation is not null at this point (because we just checked it in the previous condition).

### Finding Alternative Stations

```dart
  Station? get suggestedAlternativeDockStation {
    if (!showFullStationRerouteAlert) {
      return null;
    }

    final Station selected = _selectedStation!;
    Station? nearestStation;
    double? nearestDistance;

    for (final Station station in _stations) {
      if (station.id == selected.id || station.freeDocks <= 0) {
        continue;
      }

      final double distance = _distanceSquared(selected, station);

      if (nearestStation == null || distance < nearestDistance!) {
        nearestStation = station;
        nearestDistance = distance;
      }
    }

    return nearestStation;
  }
```

This getter finds the nearest alternative station when the selected station is full. First, it checks if we should even suggest an alternative - if the alert shouldn't show, it returns null immediately. Then it stores the selected station in a local variable for easy access. It initializes variables to track the nearest station found and its distance. The method loops through all stations, skipping the currently selected one and any stations without free docks using the "continue" statement to jump to the next iteration. For each valid station, it calculates the squared distance using a helper method (squared distance is faster to compute than actual distance since it avoids the expensive square root operation). If this is the first valid station or it's closer than the previous nearest, it updates the tracking variables. Finally, it returns the nearest station with free docks, or null if none were found.

### Loading Stations

```dart
  Future<void> loadStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stations = await _repository.fetchStations();
      if (_selectedStation != null) {
        _selectedStation = _findStationById(_selectedStation!.id);
      }
    } on Exception {
      _errorMessage = 'Unable to load stations. Please try again.';
      _stations = <Station>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
```

The loadStations method is an asynchronous function that fetches station data from the repository. The "async" keyword enables the use of "await" for asynchronous operations. First, it sets the loading flag to true and clears any previous error messages, then calls notifyListeners() to update the UI with a loading spinner. The try block attempts to fetch stations from the repository using "await", which pauses execution until the data arrives. If a station was previously selected, it refreshes that selection with updated data to ensure availability information is current. The "on Exception" catch block handles any errors that occur during fetching by setting an error message and clearing the stations list. The finally block always executes regardless of success or failure, setting loading to false and notifying listeners so the UI can update with either the new data or the error message.

### Station Selection and Management

```dart
  void selectStation(String stationId) {
    final Station? station = _findStationById(stationId);
    if (station == null) {
      return;
    }
    _selectedStation = station;
    notifyListeners();
  }
```

This method is called when the user taps on a station marker on the map. It takes the station's ID as a parameter and uses a private helper method to find the corresponding Station object in the internal list. If the station isn't found (which would be unusual but possible if data hasn't loaded yet), the method returns early without making any changes. Otherwise, it updates the selected station field and calls notifyListeners() to trigger a UI rebuild, which will display the station information popup.

```dart
  void clearSelectedStation() {
    if (_selectedStation == null) {
      return;
    }
    _selectedStation = null;
    notifyListeners();
  }
```

This method deselects the currently selected station, typically called when the user taps outside the info popup or presses a close button. As an optimization, it first checks if there's actually a selected station - if nothing is selected, it returns early without triggering an unnecessary UI rebuild. If a station is selected, it clears the selection and notifies listeners to update the UI and hide the popup.

### Ride State Management

```dart
  void setHasActiveRide(bool value) {
    if (_hasActiveRide == value) {
      return;
    }
    _applyRideState(isActive: value);
    notifyListeners();
  }
```

This method allows external code to manually set whether the user has an active ride. It first checks if the state is already the desired value to avoid unnecessary work - if it's already set to that value, it returns early. Otherwise, it calls a private helper method to apply all the state changes associated with starting or ending a ride, then notifies listeners to update the UI.

```dart
  bool activateRideFromScan() {
    if (_hasActiveRide) {
      return false;
    }
    _applyRideState(isActive: true);
    notifyListeners();
    return true;
  }
```

This method is specifically called when the user scans a QR code to start a ride. It returns a boolean indicating success or failure. If the user already has an active ride, it returns false immediately - you can't start a second ride while one is active. Otherwise, it activates the ride state and returns true to indicate success. The calling code can use this return value to display appropriate messages to the user.

```dart
  bool endActiveRide() {
    if (!_hasActiveRide) {
      return false;
    }
    _applyRideState(isActive: false);
    notifyListeners();
    return true;
  }
```

This method ends the current ride and returns a boolean indicating whether the operation was successful. If there's no active ride to end, it returns false. Otherwise, it deactivates the ride state and returns true. This method might be called when the user explicitly ends a ride without returning it to a station.

### Returning a Bike

```dart
  ReturnBikeResult returnBikeToStation(Station station) {
    if (!_hasActiveRide) {
      return ReturnBikeResult.noActiveRide;
    }

    final Station? matchedStation = _findStationById(station.id);
    final Station targetStation = matchedStation ?? station;

    if (targetStation.freeDocks <= 0) {
      return ReturnBikeResult.stationFull;
    }

    if (matchedStation != null) {
      _stations = _stations
          .map((Station currentStation) {
            if (currentStation.id != matchedStation.id) {
              return currentStation;
            }
            return currentStation.copyWith(
              availableBikes: currentStation.availableBikes + 1,
            );
          })
          .toList(growable: false);
    }

    _applyRideState(isActive: false);
    notifyListeners();
    return ReturnBikeResult.success;
  }
```

This method handles the logic of returning a bike to a station and returns an enum indicating the result. First, it checks if the user has an active ride - if not, it returns a failure status immediately. Then it tries to find the station in the internal list to get the most up-to-date data. The null-coalescing operator (??) means "use the matched station if found, otherwise use the provided station." Next, it checks if the target station has free docks - if it's full, it returns a failure status. If the station was found in our list, it updates the station data by creating a new list where the returned-to station has one more available bike. The map() function transforms each station, keeping non-matching stations unchanged and updating the matching station with incremented bike count. The copyWith() method creates a new Station object with modified values while keeping other properties unchanged. Finally, it ends the ride and notifies listeners, returning a success status.

### Banner and Alert Management

```dart
  bool dismissReturnModeBanner() {
    if (!showReturnModeBanner) {
      return false;
    }
    _isReturnBannerVisible = false;
    notifyListeners();
    return true;
  }
```

This method is called when the user taps the close button on the return mode banner. It returns a boolean indicating whether the banner was actually dismissed. If the banner isn't currently showing, it returns false without making changes. Otherwise, it sets the visibility flag to false (while keeping the active ride state unchanged, so the user stays in return mode) and returns true. This separation allows users to have a cleaner interface while still being in return mode.

```dart
  void toggleReturnModeForTesting() {
    _applyRideState(isActive: !_hasActiveRide);
    notifyListeners();
  }
```

This is a debug-only method that toggles return mode on and off, useful during development for testing the return mode UI without having to actually scan QR codes. The exclamation mark (!) is the logical NOT operator, which flips true to false and vice versa. This method should not be called in production code.

```dart
  void rerouteToSuggestedDock() {
    final Station? suggestion = suggestedAlternativeDockStation;
    if (suggestion == null) {
      return;
    }
    _selectedStation = suggestion;
    notifyListeners();
  }
```

When a station is full and the UI displays an alert suggesting an alternative, the user can tap a button that calls this method to automatically navigate to the suggested station. It retrieves the suggested alternative using the computed property we defined earlier. If no suggestion is available (which shouldn't happen if the UI is showing the alert correctly), it returns early. Otherwise, it updates the selected station to the suggestion and notifies listeners, causing the map to update and show information for the alternative station.

### Location Services

```dart
    if (result.status != UserLocationStatus.located ||
        result.coordinate == null) {
      return result.status;
    }
```
→ Check if location was successfully obtained
→ If failed (denied, disabled, etc.), return status immediately

```dart
    _mapCenter = result.coordinate!;
    _currentUserLocation = result.coordinate!;
    _locateRequestVersion += 1;
    notifyListeners();
    return UserLocationStatus.located;
  }
```
→ Success: update map center to user's location
→ Store user location
→ Increment version counter (triggers map camera animation)
→ Notify UI to rebuild
→ Return success status

### Availability Helpers

```dart
  bool hasAvailabilityForCurrentMode(Station station) {
    return isReturnMode ? station.freeDocks > 0 : station.availableBikes > 0;
  }
```

This helper method checks whether a station is useful in the current mode. The ternary operator (? :) provides a concise if-else expression. When in return mode (user has a bike to return), the method returns true only if the station has free docks. In normal mode (user wants to rent a bike), it returns true only if bikes are available. This method is used throughout the app to determine which stations to highlight, filter, or sort.

```dart
  String availabilityLabelForCurrentMode(Station station) {
    return isReturnMode
        ? '${station.freeDocks} Docks'
        : '${station.availableBikes} Bikes';
  }
```

This method generates the appropriate display text for a station's availability based on the current mode. In return mode, it shows the number of free docks (e.g., "5 Docks"), while in normal mode it shows available bikes (e.g., "3 Bikes"). The ${} syntax is Dart's string interpolation, which inserts the variable's value into the string.

### Search Functionality

```dart
  List<Station> searchStations(String query) {
    final String normalizedQuery = query.trim().toLowerCase();

    final List<Station> results = _stations
        .where((Station station) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          final String name = station.name.toLowerCase();
          final String address = station.address.toLowerCase();
          return name.contains(normalizedQuery) ||
              address.contains(normalizedQuery);
        })
        .toList(growable: true);

    if (isReturnMode) {
      results.sort((Station a, Station b) {
        final bool aHasAvailability = hasAvailabilityForCurrentMode(a);
        final bool bHasAvailability = hasAvailabilityForCurrentMode(b);
        if (aHasAvailability != bHasAvailability) {
          return aHasAvailability ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
    }

    return results.toList(growable: false);
  }
```

This method implements station search functionality with intelligent filtering and sorting. It first normalizes the search query by trimming whitespace and converting to lowercase, making the search case-insensitive and whitespace-tolerant. The where() method filters the stations list, checking each station to see if it matches the criteria. If the query is empty, all stations are included. Otherwise, it converts the station's name and address to lowercase and checks if either contains the search query using the logical OR operator (||). The filtered results are converted to a list. In return mode, the results are sorted using a custom comparator function. Stations with availability (free docks in return mode) are prioritized and appear first in the list (returning -1 puts station 'a' before station 'b'). Within each group (available vs. full), stations are sorted alphabetically using the compareTo() method. Finally, the method returns an immutable copy of the results.

### Private Helper Methods

```dart
  Station? _findStationById(String id) {
    for (final Station station in _stations) {
      if (station.id == id) {
        return station;
      }
    }
    return null;
  }
```

This is a private helper method that searches for a station by its ID. It uses a simple for loop to iterate through all stations in the internal list. When it finds a station with a matching ID, it immediately returns that Station object. If it loops through all stations without finding a match, it returns null. This method is used throughout the ViewModel whenever we need to look up a station by its identifier.

```dart
  double _distanceSquared(Station a, Station b) {
    final double latDiff = a.latitude - b.latitude;
    final double lngDiff = a.longitude - b.longitude;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }
```

This helper method calculates the squared Euclidean distance between two stations. Rather than calculating the actual distance (which requires an expensive square root operation), it returns the squared distance. This is sufficient for comparing distances since if distance A squared is less than distance B squared, then distance A is also less than distance B. The calculation uses the Pythagorean theorem: distance squared equals the sum of the squared differences in latitude and longitude.

```dart
  void _applyRideState({required bool isActive}) {
    _hasActiveRide = isActive;
    _selectedStation = null;
    _isReturnBannerVisible = isActive;
  }
}
```

This private helper method consolidates all the state changes that occur when starting or ending a ride. It sets the active ride status to the provided value, clears any selected station (providing a clean slate), and sets the banner visibility to match the active state (shown when activating, hidden when ending). By centralizing these changes in one method, we ensure consistency and make the code easier to maintain.

---

## File 2: RideMapScreen (Live Ride Tracking)
**Path:** `lib/ui/screens/active_ride/ride_map_screen.dart`

### Import Statements

```dart
import 'dart:async';
```

This imports Dart's async library, which provides the Timer class. We need Timer to implement periodic location updates that refresh the user's position on the map every 5 seconds during an active ride.

```dart
import 'package:final_project_velotolouse/domain/model/location/geo_coordinate.dart';
import 'package:final_project_velotolouse/domain/model/location/user_location_result.dart';
```

These imports bring in the location-related domain models. GeoCoordinate represents a point on the map with latitude and longitude, while UserLocationResult encapsulates the outcome of a location request along with the coordinate if successful.

```dart
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/location/user_location_repository.dart';
import 'package:final_project_velotolouse/domain/repositories/rides/ride_repository.dart';
```

These import the repository interfaces that define how we interact with bikes, location services, and ride sessions. By depending on interfaces rather than concrete implementations, we maintain flexibility and testability.

```dart
import 'package:final_project_velotolouse/ui/controllers/ride_timer_controller.dart';
```

This imports the RideTimerController, which is a stopwatch-backed timer that tracks the ride duration. The timer is shared between the ActiveRideScreen and RideMapScreen to ensure continuous time tracking.

```dart
import 'package:final_project_velotolouse/ui/screens/station_map/widgets/station_google_map_canvas.dart';
```

This imports the Google Maps widget that we're reusing from the station map screen. Rather than creating a separate map widget for ride tracking, we leverage the existing canvas with different configuration.

```dart
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
```

These imports provide the app's theme definitions, Flutter's core Material Design widgets, and the Provider package for dependency injection and state management.

### Widget Declaration

```dart
class RideMapScreen extends StatefulWidget {
  const RideMapScreen({
    super.key,
    required this.rideTimer,
    required this.bikeCode,
    required this.stationName,
    required this.sessionId,
  });
```

RideMapScreen is declared as a StatefulWidget because it has mutable state that changes over time (user location, timer updates, loading states). The constructor requires several parameters: the shared timer, bike code, station name, and session ID. The "super.key" passes the optional key parameter to the parent StatefulWidget class for widget identity management.

```dart
  final RideTimerController rideTimer;
  final String bikeCode;
  final String stationName;
  final String sessionId;
```

These are immutable properties passed from the previous screen (ActiveRideScreen). The timer is particularly important because it's shared between screens, ensuring the elapsed time continues uninterrupted when navigating. The bike code and session ID are needed to lock the bike and end the ride on the backend.

```dart
  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}
```

This required method creates and returns the State object that holds the mutable state for this widget. Flutter calls this method once when the widget is first inserted into the widget tree.

### State Class Declaration

```dart
class _RideMapScreenState extends State<RideMapScreen> {
  static const GeoCoordinate _defaultCenter = GeoCoordinate(
    latitude: 43.6046,
    longitude: 1.4442,
  );
```

The State class contains all the mutable state for the ride map screen. It defines a static constant for the default map center (Toulouse city center), which is used as the initial map position before we successfully obtain the user's GPS location.

```dart
  GeoCoordinate _mapCenter = _defaultCenter;
  GeoCoordinate? _userLocation;
  int _locateRequestVersion = 0;
  Timer? _locationRefreshTimer;
  bool _isEndingRide = false;
  bool _depsInitialized = false;
```

These state variables track various aspects of the ride: _mapCenter determines where the map is centered, _userLocation stores the user's actual GPS position (null until located), _locateRequestVersion is a counter that increments with each location update to trigger map animations, _locationRefreshTimer holds the periodic timer that refreshes location every 5 seconds, _isEndingRide prevents double-tap on the End Ride button, and _depsInitialized ensures we only read dependencies from Provider once.

```dart
  late UserLocationRepository _locationRepo;
  late RideRepository _rideRepo;
  late BikeRepository _bikeRepo;
```

These variables store references to the repository instances obtained from Provider. The "late" keyword indicates they will be initialized before first use (specifically, in didChangeDependencies). Storing these references prevents context-related crashes in async code, since we capture them once when the context is valid rather than trying to read from context after await operations.
  late BikeRepository _bikeRepo;
```

These variables store references to the repository instances obtained from Provider. The "late" keyword indicates they will be initialized before first use (specifically, in didChangeDependencies). Storing these references prevents context-related crashes in async code, since we capture them once when the context is valid rather than trying to read from context after await operations.
```
→ late means "will be initialized before use"
→ We initialize these in didChangeDependencies()
→ Storing repository references prevents context errors in async code

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _locationRepo = context.read<UserLocationRepository>();
      _rideRepo = context.read<RideRepository>();
      _bikeRepo = context.read<BikeRepository>();
    }
  }
```
→ didChangeDependencies() called when widget's dependencies change
→ Called after initState() but before build()
→ Safe place to call context.read<T>()
→ Guard flag ensures we only read once (not on every rebuild)
→ Store repositories in instance variables so async code can use them

```dart
  @override
  void initState() {
    super.initState();
    widget.rideTimer.addListener(_onTimerTick);
```
→ initState() called once when State object is created
→ Add listener to timer so UI rebuilds every second
→ widget.rideTimer accesses the timer from parent widget

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLocation());
```
→ Schedule location refresh to happen after first frame renders
→ addPostFrameCallback ensures UI appears before GPS request
→ Underscore (_) parameter means "unused parameter"

```dart
    _locationRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLocation(),
    );
  }
```
→ Create repeating timer that fires every 5 seconds
→ Each tick calls _refreshLocation()
→ Tracks user's movement during ride

```dart
  void _onTimerTick() {
    if (mounted) setState(() {});
  }
```
→ Called every second by timer
→ mounted checks if widget still exists
→ setState() with empty body triggers rebuild (displays updated time)

```dart
  Future<void> _refreshLocation() async {
    if (!mounted) return;
```
→ Async method to get user's current location
→ Early return if widget was disposed (safety check)

```dart
    final UserLocationResult result = await _locationRepo.getCurrentLocation();
    if (!mounted) return;
```
→ Request location from repository (pauses until result)
→ Check mounted again (widget might have been disposed during await)

```dart
    if (result.status == UserLocationStatus.located &&
        result.coordinate != null) {
      setState(() {
        _userLocation = result.coordinate;
        _mapCenter = result.coordinate!;
        _locateRequestVersion++;
      });
    }
  }
```
→ If location successful, update state
→ Store user location for blue marker
→ Move map center to follow user
→ Increment version to trigger map camera animation
→ setState() tells Flutter to rebuild

```dart
  @override
  void dispose() {
    widget.rideTimer.removeListener(_onTimerTick);
    _locationRefreshTimer?.cancel();
    super.dispose();
  }
```
→ dispose() called when widget removed from tree
→ Remove timer listener (prevents memory leak)
→ Cancel location refresh timer
→ Question mark (?.) means "call only if not null"
→ Must call super.dispose() last

```dart
  Future<void> _onEndRide() async {
    if (_isEndingRide) return;
```
→ Handler for End Ride button press
→ Prevent double-execution if button tapped twice

```dart
    setState(() => _isEndingRide = true);
    _locationRefreshTimer?.cancel();
    widget.rideTimer.pause();
```
→ Set flag to true (disables button, shows spinner)
→ Stop location tracking
→ Pause ride timer

```dart
    final NavigatorState navigator = Navigator.of(context);
```
→ CRITICAL: Capture navigator BEFORE any await
→ After await, context might be invalid (widget disposed)
→ NavigatorState stays valid even after widget gone

```dart
    await Future.wait([
      _rideRepo.endRide(widget.sessionId),
      _bikeRepo.lockBike(widget.bikeCode),
    ]);
```
→ Run two async operations in parallel
→ Future.wait() waits for BOTH to complete
→ Faster than sequential await calls
→ End ride in backend and lock the bike

```dart
    navigator.popUntil((Route<dynamic> r) => r.isFirst);
  }
```
→ Navigate back to home screen
→ popUntil() removes all routes until condition is true
→ r.isFirst checks if route is the first/bottom route
→ No mounted check needed (navigator is safe)

```dart
  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
```
→ build() creates the widget tree (called every setState)
→ Get bottom safe area padding (for iPhone notch, etc.)

```dart
    return Scaffold(
      body: Stack(
        children: <Widget>[
```
→ Scaffold provides app structure
→ Stack layers widgets on top of each other
→ Children drawn in order (first = bottom, last = top)

```dart
          Positioned.fill(
            child: StationGoogleMapCanvas(
              stations: const [],
              isReturnMode: false,
              selectedStation: null,
              mapCenter: _mapCenter,
              currentUserLocation: _userLocation,
              locateRequestVersion: _locateRequestVersion,
              onStationTap: (_) {},
              fallbackMarkerPositions: const {},
            ),
          ),
```
→ Positioned.fill makes map occupy entire screen
→ Empty stations list (no station markers in ride mode)
→ Pass user location for blue marker
→ Pass version so map animates on location updates
→ Empty onStationTap handler (no interaction needed)

```dart
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
```
→ Position timer banner at top
→ left: 0, right: 0 makes it full-width
→ SafeArea adds padding for status bar, notch

```dart
              bottom: false,
```
→ Only apply safe area padding at top, not bottom

```dart
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
```
→ Outer padding: 16px left/right, 8px top/bottom
→ Green rounded container with shadow
→ 0xFF4CAF50 is hex color (green)
→ withOpacity(0.18) makes shadow semi-transparent
→ Offset(0, 2) moves shadow down 2 pixels

```dart
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
```
→ Horizontal row of widgets
→ Timer icon (white, 22px)
→ 8px spacing

```dart
                      const Expanded(
                        child: Text(
                          'Ride in progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
```
→ Expanded makes text take available space
→ Pushes time to the right

```dart
                      Text(
                        widget.rideTimer.formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
```
→ Display timer (HH:MM:SS format)
→ Larger font, bold, extra letter spacing
→ Rebuilds every second as timer ticks

```dart
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomPadding + 24,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEndingRide ? null : _onEndRide,
```
→ Position button at bottom with safe area padding
→ 24px from left/right edges
→ SizedBox with double.infinity makes button full-width
→ null disables button, _onEndRide calls handler

```dart
                icon: _isEndingRide
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.stop_circle_outlined),
```
→ Conditional icon (ternary operator)
→ If ending: show loading spinner
→ Otherwise: show stop icon

```dart
                label: const Text(
                  'End Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.warning.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
```
→ Button label text
→ Style customization:
  - backgroundColor: orange/yellow warning color
  - foregroundColor: white text
  - disabledBackgroundColor: faded when disabled
  - 16px vertical padding (tall button)
  - Rounded corners (14px radius)
  - elevation: 4 gives shadow depth

---

## File 3: RideTimerController (Stopwatch Logic)
**Path:** `lib/ui/controllers/ride_timer_controller.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
```
→ Import Timer and ChangeNotifier

```dart
class RideTimerController extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
```
→ Stopwatch is Dart's built-in high-precision timer
→ _ticker is periodic timer that fires notifications
→ Nullable because timer only exists when running

```dart
  bool get isRunning => _stopwatch.isRunning;
```
→ Check if stopwatch is currently running

```dart
  Duration get elapsed => _stopwatch.elapsed;
```
→ Get total elapsed time as Duration object

```dart
  String get formattedTime {
    final int total = elapsed.inSeconds;
    final int h = total ~/ 3600;
    final int m = (total % 3600) ~/ 60;
    final int s = total % 60;
    return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
  }
```
→ Convert elapsed time to HH:MM:SS format
→ ~/ is integer division (truncates decimal)
→ % is modulo (remainder)
→ _pad() adds leading zero (01:05:09)

```dart
  void start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }
```
→ Start the timer
→ If already running, do nothing
→ Start stopwatch
→ ??= assigns only if null (doesn't overwrite existing timer)
→ Timer fires every second, calls notifyListeners()

```dart
  void pause() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }
```
→ Pause timer (keeps elapsed time)
→ Stop stopwatch
→ Cancel ticker
→ Set ticker to null
→ Notify UI of state change

```dart
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }
```
→ Stop and reset to 00:00:00
→ .. is cascade operator (chain calls on same object)
→ Cancel ticker and notify

```dart
  @override
  void dispose() {
    _stopwatch.stop();
    _ticker?.cancel();
    super.dispose();
  }
```
→ Cleanup when controller destroyed
→ Stop everything to prevent memory leaks

```dart
  static String _pad(int value) => value.toString().padLeft(2, '0');
}
```
→ Helper to pad single digits: 5 → "05"
→ padLeft(2, '0') means "ensure 2 chars, pad with 0"

---

## Key Concepts Summary

### 1. **State Management (ChangeNotifier)**
- ViewModel extends ChangeNotifier
- When state changes, call `notifyListeners()`
- UI widgets watch with `context.watch<T>()`
- Widgets rebuild automatically on state changes

### 2. **Async/Await Pattern**
```dart
Future<void> loadData() async {
  final result = await repository.fetchData();  // Pauses here
  setState(() { data = result; });  // Continues after data arrives
}
```

### 3. **Context Safety**
- Never use `context` after `await` in async functions
- Capture `Navigator.of(context)` BEFORE await
- Use `mounted` check before setState()

### 4. **Dependency Injection**
```dart
// Provide dependencies at app root
ChangeNotifierProvider<ViewModel>(
  create: (_) => ViewModel(repository: mockRepo),
)

// Read in widgets
final viewModel = context.watch<ViewModel>();
```

### 5. **Nullable vs Non-Nullable**
```dart
String name;          // Non-nullable, must have value
String? nickname;     // Nullable, can be null
nickname!.length;     // ! asserts not null (crashes if null)
nickname?.length;     // ?. returns null if nickname is null
```

### 6. **Computed Properties**
```dart
bool get isReturnMode => _hasActiveRide;  // Recalculated each time
```
→ No stored value, computed on demand
→ Always reflects current state

---

## File 4: Repository Pattern (Data Layer Architecture)

### Repository Interfaces (Domain Layer)

**Path:** `lib/domain/repositories/stations/station_repository.dart`

```dart
import 'package:final_project_velotolouse/domain/model/stations/station.dart';

abstract class StationRepository {
  Future<List<Station>> fetchStations();
}
```

This defines an abstract interface for station data operations. The "abstract class" keyword means this class cannot be instantiated directly - it only defines a contract that other classes must implement. The interface declares a single method "fetchStations" that returns a Future (asynchronous result) containing a list of Station objects. By defining this interface in the domain layer, we separate business logic from data sources. The ViewModel depends on this interface, not on any specific implementation, which makes the code more flexible and testable.

**Why use interfaces?**
- **Flexibility:** Swap implementations without changing business logic
- **Testability:** Use mock implementations in tests
- **Decoupling:** Domain layer doesn't know about implementation details
- **Multiple sources:** Can have MockRepository, ApiRepository, CacheRepository, etc.

**Path:** `lib/domain/repositories/bikes/bike_repository.dart`

```dart
abstract class BikeRepository {
  Future<BikeSlot?> getBikeByCode(String code);
  Future<bool> unlockBike(String code);
  Future<bool> lockBike(String code);
}
```

The BikeRepository interface defines three operations: getting bike information by code (returns nullable BikeSlot since the bike might not exist), unlocking a bike (returns boolean indicating success), and locking a bike (returns boolean indicating success). These methods represent the contract for bike-related data operations that the UI layer can call without knowing where the data comes from or how it's stored.

### Repository Implementations (Data Layer)

**Path:** `lib/data/repositories/stations/station_repository_mock.dart`

```dart
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/repositories/stations/station_repository.dart';

class MockStationRepository implements StationRepository {
  @override
  Future<List<Station>> fetchStations() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const <Station>[
      Station(
        id: 'capitole-square',
        name: 'Capitole Square',
        address: 'Place du Capitole, 31000 Toulouse',
        availableBikes: 3,
        totalCapacity: 12,
        latitude: 43.6044,
        longitude: 1.4442,
      ),
      Station(
        id: 'jean-jaures',
        name: 'Jean Jaures',
        address: 'Jean Jaures, 31000 Toulouse',
        availableBikes: 5,
        totalCapacity: 5,
        latitude: 43.6061,
        longitude: 1.4492,
      ),
      Station(
        id: 'carmes',
        name: 'Carmes',
        address: 'Place des Carmes, 31000 Toulouse',
        availableBikes: 8,
        totalCapacity: 16,
        latitude: 43.5994,
        longitude: 1.4449,
      ),
    ];
  }
}
```

This is a concrete implementation of the StationRepository interface. The "implements" keyword indicates this class fulfills the contract defined by the interface. The @override annotation (best practice in Dart) indicates this method overrides an abstract method from the interface. The implementation simulates a network delay of 250 milliseconds using Future.delayed(), making the UI loading states more realistic during development. The method returns a const list of three hardcoded Station objects representing real locations in Toulouse. Using "const" means this list is created at compile-time and reused, which is more efficient than creating new objects each time.

**When to use Mock vs Real Repository:**
- **Development:** Use mock for fast iteration without backend
- **Testing:** Use mock for predictable, fast unit tests
- **Production:** Use real repository that calls actual APIs
- **Offline Mode:** Use cache repository for offline functionality

**Benefits of this pattern:**
1. **Development Speed:** Work on UI without waiting for backend
2. **Reliable Testing:** Tests don't depend on network or external services
3. **Controlled Data:** Easily test edge cases (empty lists, errors, etc.)
4. **Easy Switching:** Change one line in dependency injection to switch implementations

---

## File 5: App Structure & Navigation

**Path:** `lib/app.dart`

### Main App Widget

```dart
import 'package:final_project_velotolouse/ui/routing/app_router.dart';
import 'package:final_project_velotolouse/ui/screens/station_map/station_map_screen.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:final_project_velotolouse/ui/screens/profile/profile_screen.dart';
import 'package:final_project_velotolouse/ui/widgets/custom_bottom_nav_bar.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

class VeloToulouseApp extends StatelessWidget {
  const VeloToulouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'VeloToulouse',
      theme: appTheme,
      home: const MainShell(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
```

The VeloToulouseApp is the root widget of the entire application. It's a StatelessWidget because it has no mutable state - it just configures and builds the MaterialApp. The MaterialApp widget is Flutter's top-level container that provides material design functionality, navigation, theming, and localization. Let's break down each property:

- **debugShowCheckedModeBanner: false** - Removes the "DEBUG" banner in top-right corner
- **locale** - Gets locale from DevicePreview for testing different languages
- **builder** - Wraps app in DevicePreview for testing on different screen sizes
- **title** - App name shown in task switcher and system UI
- **theme** - Applies custom theme (colors, fonts, button styles)
- **home** - The initial screen (MainShell with bottom navigation)
- **onGenerateRoute** - Handler for named route navigation (QR scanner, ride screens)

### Main Shell with Bottom Navigation

```dart
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StationMapScreen(), // Ride tab — LK-Hour's map
    ProfileScreen(),    // Profile tab
  ];

  void _onQrTap() {
    Navigator.pushNamed(context, AppRoutes.qrScanner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onQrTap: _onQrTap,
      ),
    );
  }
}
```

MainShell is a StatefulWidget that manages the bottom navigation bar and switches between main screens. The state variable _currentIndex tracks which tab is currently selected (0 for map, 1 for profile). The _screens list holds the two main screen widgets - these are const because they don't change. When a tab is tapped, the onTap callback updates _currentIndex using setState(), which triggers a rebuild and displays the new screen. The _onQrTap handler uses named navigation to push the QR scanner screen onto the navigation stack. The Scaffold widget provides the basic app structure with a body (the current screen) and a bottom navigation bar.

**Navigation Patterns:**
- **Tab Navigation:** Instant switching between main screens (map/profile)
- **Push Navigation:** Stack-based navigation for temporary screens (QR scanner, ride details)
- **Named Routes:** Define routes by name in AppRoutes for cleaner navigation
- **Replacement Navigation:** Replace current screen instead of stacking (used when starting ride)

---

## File 6: ActiveRideScreen (Ride Dashboard)

**Path:** `lib/ui/screens/active_ride/active_ride_screen.dart`

### Route Arguments

```dart
class ActiveRideArgs {
  const ActiveRideArgs({
    required this.bikeCode,
    required this.stationName,
    required this.sessionId,
  });

  final String bikeCode;
  final String stationName;
  final String sessionId;
}
```

ActiveRideArgs is a data class that packages all the parameters needed by ActiveRideScreen into a single object. This makes route navigation cleaner - instead of passing multiple arguments, we pass one typed object. The class is immutable (all fields are final) and has a const constructor, making it efficient and safe. These arguments come from the QR scan result and backend response when unlocking a bike.

### Screen Declaration

```dart
class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({
    super.key,
    required this.bikeCode,
    required this.stationName,
    required this.sessionId,
  });

  final String bikeCode;
  final String stationName;
  final String sessionId;

  factory ActiveRideScreen.fromArgs(ActiveRideArgs args) => ActiveRideScreen(
        bikeCode: args.bikeCode,
        stationName: args.stationName,
        sessionId: args.sessionId,
      );

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}
```

The screen accepts three required parameters. The factory constructor "fromArgs" provides a convenient way to create the screen from an ActiveRideArgs object - this is used by the routing system. Factory constructors can return existing instances or call other constructors, providing flexibility in object creation. The properties are final because they're set once during construction and never change.

### State Initialization

```dart
class _ActiveRideScreenState extends State<ActiveRideScreen> {
  late final RideTimerController _rideTimer;
  late RideRepository _rideRepo;
  late BikeRepository _bikeRepo;
  bool _depsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _rideRepo = context.read<RideRepository>();
      _bikeRepo = context.read<BikeRepository>();
    }
  }

  @override
  void initState() {
    super.initState();
    _rideTimer = RideTimerController()..start();
    _rideTimer.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }
```

The state uses "late final" for the timer because it's initialized in initState() but never reassigned. Repository references use "late" without final because they're assigned in didChangeDependencies(). The guard flag prevents reading from context multiple times. In initState, we create a new RideTimerController and immediately start it using the cascade operator (..), which allows chaining multiple operations on the same object. We add a listener that rebuilds the UI every second to update the displayed time. The "mounted" check ensures the widget still exists before calling setState() - crucial for preventing crashes when async operations complete after disposal.

### Cleanup

```dart
  @override
  void dispose() {
    _rideTimer
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }
```

The dispose method is critical for preventing memory leaks. We use the cascade operator to remove the listener and dispose the timer in one chain. Removing the listener prevents the timer from calling setState() after the widget is destroyed (which would crash). Disposing the timer stops it and releases resources. Always call super.dispose() last to allow parent cleanup.

### UI Structure

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Green gradient header background
          Container(
            height: 400,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Checkmark icon with double-ring design
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
```

The UI uses a Stack to layer the gradient background behind the content. The gradient creates a smooth transition from darker to lighter green. SafeArea ensures content doesn't overlap with system UI like the status bar - setting bottom: false means we don't apply safe area at the bottom. The success icon uses nested containers to create a double-ring ripple effect with semi-transparent white circles. This visual design celebrates the successful bike unlock.

### Ride Information Card

```dart
                // Content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bike header with icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pedal_bike,
                                  color: AppColors.warning,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bike #${widget.bikeCode}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Slot 1 - ${widget.stationName}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
```

The Expanded widget makes the white card fill remaining space. The SingleChildScrollView allows scrolling if content is too tall for the screen. The bike header uses a Row with an icon container (background color with opacity creates a subtle tint) and an Expanded column for text. String interpolation (${}) inserts the bike code and station name into the display strings. The Expanded widget in the row ensures the text section takes available space, pushing the icon to the left.

### Statistics Display

```dart
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  value: _formattedTime,
                                  label: 'Elapsed Time',
                                  valueColor: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  value: '0.0 km',
                                  label: 'Distance',
                                  valueColor: Colors.grey[800]!,
                                ),
                              ),
                            ],
                          ),
```

The statistics are displayed in a row of two equally-sized boxes using Expanded widgets. Each _StatBox is a custom widget that displays a value (elapsed time or distance) with a label. The formatted time comes from the timer controller and updates every second. The distance is hardcoded as "0.0 km" since distance tracking isn't implemented yet. The exclamation mark after Colors.grey[800] is a null-assertion operator - we're telling Dart we're certain this color exists (grey with intensity 800).

### Navigation to Live Map

```dart
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => RideMapScreen(
                                      rideTimer: _rideTimer,
                                      bikeCode: widget.bikeCode,
                                      stationName: widget.stationName,
                                      sessionId: widget.sessionId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('View Live Map'),
                            ),
                          ),
```

The "View Live Map" button spans the full width (double.infinity). When pressed, it uses Navigator.push() to add the RideMapScreen on top of the current screen. The MaterialPageRoute builder creates the new screen. Critically, we pass the _rideTimer instance to RideMapScreen - this allows both screens to share the same timer, so the time continues counting accurately even when navigating between screens. This is a key pattern for sharing state across screens without complex state management.

**Why share the timer instance?**
- **Continuity:** Time keeps running during navigation
- **Accuracy:** No need to calculate elapsed time from timestamps
- **Simplicity:** No need for complex state synchronization
- **Reliability:** Timer state is source of truth

---

## File 7: Widget Components (Reusable UI)

### StationInfoPopup

**Path:** `lib/ui/screens/station_map/widgets/station_info_popup.dart`

```dart
class StationInfoPopup extends StatelessWidget {
  const StationInfoPopup({
    super.key,
    required this.station,
    required this.isReturnMode,
    required this.onClose,
    required this.onNavigate,
    required this.onReturnBike,
    required this.onViewStation,
  });

  final Station station;
  final bool isReturnMode;
  final VoidCallback onClose;
  final VoidCallback onNavigate;
  final VoidCallback onReturnBike;
  final VoidCallback onViewStation;
```

StationInfoPopup is a reusable widget that displays detailed information about a selected station. It's a StatelessWidget because all its data comes from parameters - it has no internal mutable state. The widget requires a Station object and several callback functions (VoidCallback is a typedef for void Function()). This design follows the "dumb component" pattern where the widget is purely presentational and delegates all actions to parent handlers.

**Why use callbacks instead of direct actions?**
- **Reusability:** Widget doesn't know about app structure
- **Testability:** Easy to verify callbacks are called
- **Flexibility:** Parent decides what happens
- **Separation:** UI logic separate from business logic

```dart
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station name and close button
          Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.neutralText,
                ),
              ),
            ],
          ),
```

The popup is a rounded container with a shadow to give it depth and make it float above the map. The padding uses fromLTRB (left, top, right, bottom) for precise control. The shadow uses hex color 0x26000000 (black with 15% opacity) with a blur radius of 10 and offset downward by 3 pixels, creating a realistic drop shadow. MainAxisSize.min makes the column only as tall as its content. The close button uses GestureDetector instead of IconButton for simpler, borderless tap handling.

### Information Pills

```dart
          Row(
            children: [
              _StationInfoPill(
                label: isReturnMode ? 'Free Docks' : 'Available Bikes',
                value: isReturnMode
                    ? '${station.freeDocks}'
                    : '${station.availableBikes}',
              ),
              const SizedBox(width: 8),
              _StationInfoPill(
                label: isReturnMode ? 'Total Capacity' : 'Empty Slots',
                value: isReturnMode
                    ? '${station.totalCapacity}'
                    : '${station.freeDocks}',
              ),
            ],
          ),
```

The information pills adapt their content based on return mode using ternary operators. When returning a bike, users care about free docks and total capacity. When renting a bike, they care about available bikes and empty slots. This context-aware display reduces cognitive load by showing only relevant information. The _StationInfoPill is a private custom widget that creates a small rounded container with a label and value.

**Adaptive UI Pattern:**
- Show different information based on user context
- Reduce clutter by hiding irrelevant data
- Use consistent visual design regardless of mode
- Make the distinction clear through labels

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                    │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │   Screens      │  │  ViewModels    │  │  Controllers  │ │
│  │  (Widgets)     │◄─┤(ChangeNotifier)│  │   (Shared)    │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
│         │                     │                    │         │
└─────────┼─────────────────────┼────────────────────┼─────────┘
          │                     │                    │
          │                     ▼                    │
          │           ┌──────────────────┐          │
          │           │  DOMAIN LAYER    │          │
          │           │   ┌──────────┐   │          │
          │           │   │  Models  │   │          │
          │           │   └──────────┘   │          │
          │           │   ┌──────────┐   │          │
          │           │   │Repository│   │          │
          │           │   │Interfaces│   │          │
          │           │   └──────────┘   │          │
          │           └──────────────────┘          │
          │                     │                    │
          ▼                     ▼                    ▼
    ┌─────────────────────────────────────────────────────┐
    │                   DATA LAYER                         │
    │  ┌──────────────────┐  ┌────────────────────────┐  │
    │  │ Repository       │  │   Repository           │  │
    │  │ Implementations  │  │   Implementations      │  │
    │  │  (Mock)          │  │   (Device GPS)         │  │
    │  └──────────────────┘  └────────────────────────┘  │
    └─────────────────────────────────────────────────────┘
```

**Data Flow:**
1. User interacts with Widget (tap button, type text)
2. Widget calls ViewModel method
3. ViewModel calls Repository interface
4. Repository implementation fetches/updates data
5. ViewModel updates internal state
6. ViewModel calls notifyListeners()
7. Watching Widgets rebuild with new data

---

## File 8: StationMapScreen (Main View - Map Display)

**Path:** `lib/ui/screens/station_map/station_map_screen.dart`

### Import Statements and Class Declaration

```dart
import 'package:final_project_velotolouse/ui/screens/station_map/view_model/station_map_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StationMapScreen extends StatelessWidget {
  const StationMapScreen({super.key});
```

StationMapScreen is the main View that displays the interactive map of bike stations. It's a **StatelessWidget** because it doesn't manage its own state - instead, it watches the StationMapViewModel for state changes. This is a key MVVM principle: the View is "dumb" and reactive, simply displaying data from the ViewModel and forwarding user actions back to it.

**Why StatelessWidget?**
- **No local state:** All state lives in ViewModel
- **Reactive:** Rebuilds automatically when ViewModel notifies
- **Testable:** Easy to test by providing mock ViewModel
- **Performant:** Flutter optimizes stateless widget rebuilds

### Fallback Marker Positions

```dart
  static const Map<String, Offset> _markerMapPosition = <String, Offset>{
    'capitole-square': Offset(0.34, 0.24),
    'jean-jaures': Offset(0.24, 0.55),
    'carmes': Offset(0.64, 0.52),
  };
```

This static constant map defines fallback positions for station markers on a static map image. The Offset values are normalized coordinates (0.0 to 1.0) representing positions relative to the image dimensions. For example, Offset(0.34, 0.24) means 34% from the left and 24% from the top. These positions are used when Google Maps isn't available or during initial loading, ensuring users always see station locations.

### Search Sheet Handler

```dart
  Future<void> _onSearchTapped(
    BuildContext context,
    StationMapViewModel viewModel,
  ) async {
    final String? selectedStationId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.baseSurfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: StationSearchSheet(
            onSearch: viewModel.searchStations,
            onSelectStation: (String stationId) {
              Navigator.of(context).pop(stationId);
            },
            isReturnMode: viewModel.isReturnMode,
            availabilityLabelForStation:
                viewModel.availabilityLabelForCurrentMode,
            canSelectStation: (Station station) {
              if (!viewModel.isReturnMode) {
                return true;
              }
              return viewModel.hasAvailabilityForCurrentMode(station);
            },
          ),
        );
      },
    );

    if (!context.mounted || selectedStationId == null) {
      return;
    }
    viewModel.selectStation(selectedStationId);
  }
```

This handler opens a bottom sheet for station search when the user taps the search field. The method is async because showModalBottomSheet returns a Future that resolves when the sheet closes. The **isScrollControlled: true** allows the sheet to take up custom height (72% via FractionallySizedBox). The sheet has rounded top corners for modern iOS-style design. The builder function passes ViewModel methods to the search sheet as callbacks, maintaining the separation between View and ViewModel. After the sheet closes, we check **context.mounted** (crucial safety check) before using the returned station ID. If a station was selected, we call the ViewModel's selectStation method to update the state.

**Key Pattern - Callback Composition:**
1. View calls ViewModel method (onSearch)
2. ViewModel performs business logic
3. ViewModel notifies listeners
4. View rebuilds with new data
→ This maintains unidirectional data flow

### Debug Mode Toggle

```dart
  void _onTopRightButtonTapped(BuildContext context) {
    if (kDebugMode) {
      context.read<StationMapViewModel>().toggleReturnModeForTesting();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Return mode switches automatically after bike booking.'),
      ),
    );
  }
```

This handler provides different behavior in debug vs production. The **kDebugMode** constant is set by Flutter at compile time. In debug builds, tapping the button toggles return mode instantly for testing. In production, it shows a helpful message explaining that return mode activates automatically. This pattern allows developers to test return mode features without actually renting a bike, significantly speeding up development cycles.

### Scan Button Handler

```dart
  void _onScanButtonPressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) {
    final bool hasStartedRide = viewModel.activateRideFromScan();
    final String message = hasStartedRide
        ? 'Bike unlocked. Return mode activated.'
        : 'Ride already active. Return your bike at an available dock.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
```

When simulating a bike unlock (in development), this handler attempts to start a ride via the ViewModel. The ViewModel returns a boolean indicating success - if the user already has an active ride, it returns false and the UI shows an appropriate message. The ternary operator selects the message based on the result. This demonstrates error handling through return values rather than exceptions, which is often clearer for business logic validation.

### Location Services Handler

```dart
  Future<void> _onLocateCurrentPositionPressed(
    BuildContext context,
    StationMapViewModel viewModel,
  ) async {
    final UserLocationStatus status = await viewModel.locateCurrentUser();
    if (!context.mounted) {
      return;
    }

    final String message = switch (status) {
      UserLocationStatus.located => 'Centered on your current location.',
      UserLocationStatus.permissionDenied =>
        'Location permission denied. Please allow GPS access.',
      UserLocationStatus.permissionDeniedForever =>
        'Location permission denied permanently. Enable it in settings.',
      UserLocationStatus.serviceDisabled =>
        'GPS is off. Please enable location services.',
      UserLocationStatus.unavailable => 'Unable to find your current location.',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
```

This async handler requests the user's location through the ViewModel. After the await, it's critical to check **context.mounted** because the widget might have been disposed during the async operation (user navigated away). The **switch expression** (Dart 3.0 feature) provides exhaustive pattern matching on the status enum, ensuring all cases are handled. Each status maps to a user-friendly message explaining what happened. This provides excellent UX by giving clear feedback for every location permission scenario.

**Switch Expression Benefits:**
- **Exhaustive:** Compiler ensures all cases covered
- **Concise:** No breaks or returns needed
- **Type-safe:** Guaranteed to return a value
- **Refactor-safe:** Adding enum value causes compile error

### Return Bike Handler

```dart
  void _onReturnBikePressed(
    BuildContext context,
    StationMapViewModel viewModel,
    Station station,
  ) {
    final ReturnBikeResult result = viewModel.returnBikeToStation(station);
    final String message = switch (result) {
      ReturnBikeResult.success => 'Bike returned successfully.',
      ReturnBikeResult.noActiveRide => 'No active ride to return.',
      ReturnBikeResult.stationFull =>
        'This station is full. Please choose another dock.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
```

When the user taps "Return Bike Here" in the station popup, this handler calls the ViewModel to process the return. The ViewModel returns an enum indicating the result, and the View uses a switch expression to display appropriate feedback. This pattern keeps validation logic in the ViewModel while the View handles presentation. If the station is full, the user sees a clear error message and can try another station.

### Build Method - Main UI Structure

```dart
  @override
  Widget build(BuildContext context) {
    final StationMapViewModel viewModel = context.watch<StationMapViewModel>();
    final Station? selectedStation = viewModel.selectedStation;

    return Scaffold(
      backgroundColor: AppColors.baseSurfaceAlt,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
```

The build method is called every time the ViewModel calls notifyListeners(). The **context.watch<StationMapViewModel>()** call registers this widget to rebuild when the ViewModel changes. We extract selectedStation to a local variable for convenient access. The Scaffold provides basic app structure, SafeArea ensures content doesn't overlap system UI, and Stack allows layering widgets (map at bottom, controls on top).

**context.watch vs context.read:**
- **watch()** - Subscribe to changes, rebuilds widget
- **read()** - Get current value, no subscription
- Use watch() in build(), read() in event handlers

### Loading and Error States

```dart
            Positioned.fill(
              child: Container(
                color: AppColors.mapBackground,
                child: Stack(
                  children: <Widget>[
                    if (viewModel.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (viewModel.errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: viewModel.loadStations,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: StationGoogleMapCanvas(
                          stations: viewModel.stations,
                          isReturnMode: viewModel.isReturnMode,
                          selectedStation: selectedStation,
                          mapCenter: viewModel.mapCenter,
                          currentUserLocation: viewModel.currentUserLocation,
                          locateRequestVersion: viewModel.locateRequestVersion,
                          fallbackMarkerPositions: _markerMapPosition,
                          onStationTap: viewModel.selectStation,
                        ),
                      ),
```

This demonstrates proper state management with three distinct UI states: loading (spinner), error (message + retry button), and success (map display). The **if-else** chain in the widget tree ensures only one state displays at a time. In error state, the retry button directly calls viewModel.loadStations, allowing the user to recover from network failures. The map canvas receives all necessary data from the ViewModel, including the station list, current mode, user location, and callbacks for interactions.

**Three-State Pattern:**
1. **Loading:** Show spinner while fetching data
2. **Error:** Show message and recovery action
3. **Success:** Show actual content
→ Always handle all three states explicitly

### Adaptive Top Bar

```dart
                    if (viewModel.showReturnModeBanner)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: ReturnModeBanner(
                          onClose: () => _onReturnModeBannerClose(viewModel),
                        ),
                      )
                    else
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 12,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: StationMapSearchField(
                                placeholderText: viewModel.isReturnMode
                                    ? 'Find a station with free docks...'
                                    : 'Find a station or destination...',
                                onTap: () =>
                                    _onSearchTapped(context, viewModel),
                              ),
                            ),
                            if (!viewModel.isReturnMode) ...<Widget>[
                              const SizedBox(width: 10),
                              StationMapModeButton(
                                isReturnMode: viewModel.isReturnMode,
                                onTap: () => _onTopRightButtonTapped(context),
                              ),
                            ],
                          ],
                        ),
                      ),
```

The top bar adapts based on mode: in return mode, it shows a dismissible banner alerting the user they need to return their bike. In normal mode, it shows a search bar and mode toggle button. The search field's placeholder text also adapts to the current mode, providing context-appropriate guidance. The spread operator (...) conditionally includes widgets in the list - the mode button only appears in normal mode since it's not needed during an active ride.

**Conditional Widget Patterns:**
- **if (condition) widget** - Single widget
- **if (condition) ...[widgets]** - Multiple widgets (spread)
- **condition ? widget1 : widget2** - Ternary for two options

### Station Selection Popup

```dart
                    if (selectedStation != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 122,
                        child: viewModel.showFullStationRerouteAlert
                            ? StationRerouteAlert(
                                selectedStation: selectedStation,
                                suggestedStation:
                                    viewModel.suggestedAlternativeDockStation,
                                onReroute: viewModel.rerouteToSuggestedDock,
                                onClose: viewModel.clearSelectedStation,
                              )
                            : StationInfoPopup(
                                station: selectedStation,
                                isReturnMode: viewModel.isReturnMode,
                                onClose: viewModel.clearSelectedStation,
                                onNavigate: () => _onNavigateHerePressed(
                                  context,
                                  selectedStation,
                                ),
                                onReturnBike: () => _onReturnBikePressed(
                                  context,
                                  viewModel,
                                  selectedStation,
                                ),
                                onViewStation: () => _onViewStationPressed(
                                  context,
                                  selectedStation,
                                ),
                              ),
                      ),
```

When a station is selected, the UI shows one of two popups: if the user is trying to return a bike to a full station, it shows a reroute alert with a suggestion for the nearest alternative. Otherwise, it shows the standard info popup with station details and action buttons. All callbacks are passed as closures that capture the current context and selected station, allowing the child widgets to trigger actions without knowing about the parent's structure. This exemplifies the "dumb component" pattern where child widgets are purely presentational.

---

## File 9: QrScannerScreen (QR Code Scanning View)

**Path:** `lib/ui/screens/qr_scanner/qr_scanner_screen.dart`

### Imports and Class Declaration

```dart
import 'package:final_project_velotolouse/domain/repositories/bikes/bike_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}
```

QrScannerScreen is a **StatefulWidget** because it manages local UI state (animation, scanning status) that's not part of the app's business logic. The mobile_scanner package provides cross-platform QR code scanning. Unlike StationMapScreen, this screen doesn't need a ViewModel because it only performs one simple action: scan a code and navigate to the next screen.

**When to use State vs ViewModel:**
- **Local UI state** (animation, form input) → State
- **Business logic** (validation, data fetching) → ViewModel
- **Shared state** (user session, cart) → ViewModel
- **Ephemeral state** (current tab) → State

### State Initialization

```dart
class _QrScannerScreenState extends State<QrScannerScreen> 
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.front,
  );
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFlashOn = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (kIsWeb) {
      initWebCamera(onQrDetected: _handleCodeFound);
    }
  }
```

The **SingleTickerProviderStateMixin** is required for creating animations - it provides the **vsync** parameter that syncs animations with screen refresh. The scanner controller manages the camera, set to front-facing for easier QR code scanning. The animation controller creates a scanning line that moves up and down continuously using **repeat(reverse: true)**. The Tween defines the animation range (5% to 90% of container height) and CurvedAnimation applies easing for smooth motion. The _hasScanned flag prevents processing multiple scans. On web platforms, we use a different camera implementation since mobile_scanner doesn't work in browsers.

**Animation Concepts:**
- **AnimationController:** Controls timing and lifecycle
- **Tween:** Defines start/end values
- **CurvedAnimation:** Applies easing function
- **vsync:** Syncs with display refresh (prevents off-screen animation)

### QR Code Detection

```dart
  void _onQrDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _handleCodeFound(barcode!.rawValue!);
    }
  }

  Future<void> _handleCodeFound(String code) async {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);
    _animationController.stop();

    final bikeRepo = context.read<BikeRepository>();
    final slot = await bikeRepo.getBikeByCode(code);

    if (!mounted) return;

    if (slot == null) {
      setState(() => _hasScanned = false);
      _animationController.repeat(reverse: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bike "$code" not found. Please scan again.'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.bikeConnecting,
      arguments: BikeConnectionArgs(
        bikeCode: code,
        stationName: 'Capitole Square',
      ),
    );
  }
```

When the scanner detects a QR code, it extracts the raw value and calls _handleCodeFound. The method immediately sets _hasScanned to prevent duplicate scans and stops the animation. It then validates the bike code with the repository - if the bike doesn't exist, it resets the scanning state and shows an error, allowing the user to try again. If valid, it uses **pushReplacementNamed** to replace the scanner screen with the bike connection screen, preventing the user from going back (since the scan is complete). The **mounted** check after await is critical for safety.

**Navigation Methods:**
- **push:** Add screen to stack (can go back)
- **pushReplacement:** Replace current screen (can't go back)
- **pushNamed:** Navigate by route name
- **pop:** Remove current screen

### Manual Entry Dialog

```dart
  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Bike Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'e.g., CO-04',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.warning, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(ctx);
                _handleCodeFound(controller.text.trim());
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
```

This provides a fallback for users who can't scan QR codes (broken camera, poor lighting). The dialog shows a text field with **autofocus** (keyboard appears automatically) and **textCapitalization.characters** (converts to uppercase for bike codes like "CO-04"). The decoration customizes the border appearance, with a special focused border in warning color to draw attention. The Unlock button validates that text was entered, closes the dialog, and processes the code just like a scanned QR. This demonstrates good UX by providing multiple input methods.

### UI Structure

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _toggleFlash,
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: _isFlashOn ? Colors.amber : Colors.white,
                  ),
                  Text(
                    'Flash',
                    style: TextStyle(
                      color: _isFlashOn ? Colors.amber : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
```

The screen uses a dark theme (black background) for better camera contrast. **extendBodyBehindAppBar: true** makes the camera feed go under the transparent app bar for full-screen effect. The app bar has a text-based "Cancel" button (iOS style) and a "Flash" toggle that changes color when active. Using GestureDetector instead of IconButton gives more layout control.

### Camera Feed and Overlay

```dart
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb
                ? const WebCameraView()
                : MobileScanner(
                    controller: _scannerController,
                    onDetect: _onQrDetected,
                  ),
          ),
          
          CustomPaint(
            painter: _QrScannerOverlayPainter(),
            child: Container(),
          ),
          
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 120),
              width: 340,
              height: 340,
              child: Stack(
                children: [
                  // Corner borders (4 positioned widgets)
                  if (!_hasScanned)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value * 340,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
```

The camera feed fills the screen, covered by a CustomPaint overlay that darkens everything except the scanning area. A centered 340x340 square contains four corner borders (indicating scan area) and an animated scanning line. The AnimatedBuilder rebuilds only the scanning line on each animation frame (efficient). The line's vertical position is calculated by multiplying the animation value (0.05-0.9) by the container height (340px). The glowing effect uses a box shadow with the same color at 50% opacity.

**Performance Tip:**
AnimatedBuilder only rebuilds its child, not the entire tree. This is much more efficient than using setState() for animations.

---

## File 10: ProfileScreen (Simple Placeholder View)

**Path:** `lib/ui/screens/profile/profile_screen.dart`

```dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Screen')),
    );
  }
}
```

ProfileScreen is a minimal placeholder screen showing the profile tab in the bottom navigation. It's a StatelessWidget (no state needed) that simply displays text in the center. In a full implementation, this would show user information, ride history, payment methods, and settings. The simplicity demonstrates that not all screens need complex logic - some Views are just containers for future features.

**Progressive Development Pattern:**
1. Create placeholder screens early
2. Hook up navigation
3. Implement core features first
4. Fill in secondary screens later
→ This allows testing navigation and app flow before all features are built

---

## MVVM Pattern Summary

### Complete MVVM Flow in VeloToulouse:

```
USER ACTION
    ↓
┌─────────────────────────────────────────┐
│           VIEW LAYER                    │
│  • StationMapScreen                     │
│  • ActiveRideScreen                     │
│  • RideMapScreen                        │
│  • QrScannerScreen                      │
│                                         │
│  → Displays UI                          │
│  → Handles user input                   │
│  → Calls ViewModel methods              │
│  → Watches ViewModel for changes        │
└─────────────────────────────────────────┘
    ↓ (calls method)
┌─────────────────────────────────────────┐
│        VIEWMODEL LAYER                  │
│  • StationMapViewModel                  │
│  • RideTimerController                  │
│                                         │
│  → Business logic                       │
│  → State management                     │
│  → Calls Repository                     │
│  → Notifies View via notifyListeners()  │
└─────────────────────────────────────────┘
    ↓ (calls interface)
┌─────────────────────────────────────────┐
│         MODEL LAYER                     │
│  • Station                              │
│  • GeoCoordinate                        │
│  • RideSession                          │
│  • BikeSlot                             │
│  • UserLocationResult                   │
│                                         │
│  → Pure data structures                 │
│  → No business logic                    │
│  → Immutable (final fields)             │
└─────────────────────────────────────────┘
    ↓ (passed through Repository)
┌─────────────────────────────────────────┐
│       REPOSITORY LAYER                  │
│  • StationRepository                    │
│  • BikeRepository                       │
│  • RideRepository                       │
│  • UserLocationRepository               │
│                                         │
│  → Abstracts data sources               │
│  → Interfaces for testability           │
│  → Mock/Real implementations            │
└─────────────────────────────────────────┘
```

### Key MVVM Principles Applied:

1. **Separation of Concerns**
   - View: Only presentation logic
   - ViewModel: Only business logic
   - Model: Only data structure

2. **Unidirectional Data Flow**
   - View → ViewModel (method calls)
   - ViewModel → View (notifyListeners)
   - Never: View ↔ View or ViewModel ↔ Model directly

3. **Testability**
   - ViewModels testable without UI
   - Views testable with mock ViewModels
   - Models testable in isolation

4. **Reactive Updates**
   - ViewModel extends ChangeNotifier
   - View uses context.watch()
   - Automatic rebuilds on state changes

5. **Dependency Injection**
   - ViewModels receive dependencies via constructor
   - Views receive ViewModels via Provider
   - Easy to swap implementations

---

This comprehensive script now covers the complete MVVM architecture of the VeloToulouse bike-sharing app, including all Models, ViewModels, and Views!
