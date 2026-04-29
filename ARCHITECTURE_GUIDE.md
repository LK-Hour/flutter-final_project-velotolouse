# VeloToulouse Architecture Guide
## Complete Code Explanation - Layered Architecture Pattern

**Last Updated:** April 27, 2026  
**Architecture:** Clean Layered Architecture with Services, States, and ViewModels

---

## 📐 Architecture Overview

Your VeloToulouse app follows a 5-layer clean architecture pattern that separates concerns across different responsibilities. The View Layer contains all UI components like screens and widgets. The ViewModel Layer coordinates between states, services, and the UI. The Global State Layer manages app-wide data using ChangeNotifier. The Service Layer contains pure business logic without state. Finally, the Repository Layer handles all data access operations.

```
┌──────────────────────────────────────────────────────────┐
│                    5. VIEW LAYER                         │
│  Screens, Widgets, UI Components                         │
└──────────────────────────────────────────────────────────┘
                         ↕ (observes)
┌──────────────────────────────────────────────────────────┐
│                4. VIEWMODEL LAYER                        │
│  Coordinates between States, Services, and UI            │
└──────────────────────────────────────────────────────────┘
                         ↕ (uses)
┌──────────────────────────────────────────────────────────┐
│              3. GLOBAL STATE LAYER                       │
│  App-wide state management (ChangeNotifier)              │
└──────────────────────────────────────────────────────────┘
                         ↕ (uses)
┌──────────────────────────────────────────────────────────┐
│               2. SERVICE LAYER                           │
│  Pure business logic (stateless)                         │
└──────────────────────────────────────────────────────────┘
                         ↕ (uses)
┌──────────────────────────────────────────────────────────┐
│              1. REPOSITORY LAYER                         │
│  Data access abstraction                                 │
└──────────────────────────────────────────────────────────┘
```

### 🎯 Key Principles

Each layer has a single responsibility and can be tested independently. Dependencies flow from outer layers to inner layers through dependency injection. Services contain reusable business logic that can be shared across ViewModels. This architecture makes it easy to add new features without breaking existing code.

---

## Layer 1: Service Layer (Business Logic)

### File: StationService

**Path:** `lib/services/station_service.dart`

The StationService contains all station-related business logic without holding any state. It provides pure functions that can be called from any part of the application. The service handles operations like searching stations, checking availability, and finding alternatives.

```dart
class StationService {
  List<Station> searchStations(
    List<Station> stations,
    String query, {
    required bool isReturnMode,
  }) {
```

The `searchStations()` method filters stations by normalizing the query to lowercase and searching within station names and addresses. When in return mode, it prioritizes stations with free docks by sorting them first. The method returns an immutable list to prevent accidental modifications.

The `hasAvailability()` method checks whether a station has capacity for the current mode. In return mode it checks for free docks, while in rent mode it checks for available bikes. This encapsulates the business rule in one place instead of repeating it throughout the UI.

The `findNearestStationWithDocks()` method calculates distances using squared values to avoid expensive square root operations. It filters out full stations and returns the closest alternative, or null if none exist. This helps suggest alternatives when a user's chosen station is full.

Services are designed to be reusable across different ViewModels and easy to unit test since they're stateless. All business logic lives in services rather than being scattered across ViewModels or UI components. This makes the code more maintainable and predictable.

---

### File: RideService

**Path:** `lib/services/ride_service.dart`

The RideService handles all ride-related validation and calculations. Instead of throwing exceptions for business logic failures, it uses an enum to represent different return outcomes. This makes the code more type-safe and forces developers to handle all possible cases.

```dart
enum ReturnBikeResult { 
  success, 
  noActiveRide, 
  stationFull 
}

class RideService {
  ReturnBikeResult validateReturn({
    required bool hasActiveRide,
    required Station station,
  }) {
```

The `validateReturn()` method checks two conditions before allowing a bike return: the user must have an active ride, and the station must have free docks. By returning an enum, the UI can display appropriate messages for each scenario. This pattern is more readable than checking boolean flags or catching exceptions.

The service also contains methods like `shouldShowReturnBanner()` and `shouldShowFullStationAlert()` that encapsulate UI visibility logic. These pure functions prevent complex conditionals from cluttering the UI code. They serve as a single source of truth for when certain UI elements should appear.

The `calculateElapsedTime()` method handles both active and completed rides by using either the current time or the ride's end time. This demonstrates how services can contain small, focused utility functions that might be needed by multiple ViewModels or screens.

---

## Layer 2: Global State Layer

### File: StationState

**Path:** `lib/ui/states/station_state.dart`

StationState manages all station-related data across the entire app. Multiple screens need access to the same station data, so storing it globally avoids redundant API calls. The state also manages map-related data like the current center position and user location.

```dart
class StationState extends ChangeNotifier {
  final StationRepository _repository;
  final UserLocationRepository _userLocationRepository;

  bool _isLoading = false;
  List<Station> _stations = <Station>[];
  Station? _selectedStation;
  GeoCoordinate _mapCenter = defaultMapCenter;
```

The `loadStations()` method demonstrates the typical async state update pattern. It sets loading to true and notifies listeners so the UI can show a spinner. Then it fetches data from the repository, handles both success and error cases, and finally notifies listeners again with the result.

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

The `updateStationAfterReturn()` method shows the immutable update pattern. Instead of modifying existing station objects directly, it creates a new list with a new copy of the updated station. This prevents bugs that can occur when multiple parts of the app reference the same mutable object.

```dart
void updateStationAfterReturn(String stationId) {
  _stations = _stations.map((station) {
    if (station.id != stationId) return station;
    return station.copyWith(
      availableBikes: station.availableBikes + 1,
    );
  }).toList(growable: false);
  
  if (_selectedStation?.id == stationId) {
    _selectedStation = _findStationById(stationId);
  }
  notifyListeners();
}
```

The location service integration uses a version counter pattern. The `_locateRequestVersion` increments each time the user's location is found, even if the coordinates are identical. This triggers the map to animate to the new position, since the map widget watches this counter value.

---

### File: RideState

**Path:** `lib/ui/states/ride_state.dart`

RideState manages the global ride session state including active rides and return mode. It uses a reactive stream pattern to listen for ride changes from the repository. When the repository emits a new ride session, the state automatically updates and notifies all listeners.

```dart
class RideState extends ChangeNotifier {
  final RideRepository _repository;

  RideSession? _activeRide;
  bool _hasActiveRide = false;
  bool _isReturnBannerDismissed = false;

  RideState(this._repository) {
    _watchActiveRide();
  }
```

The `_watchActiveRide()` method subscribes to the repository's stream and updates local state whenever new data arrives. This enables real-time synchronization if the backend modifies the ride data. The state also resets the banner dismissal flag when a new ride starts, ensuring users see the return mode banner for each ride.

```dart
void _watchActiveRide() {
  _repository.watchActiveRide().listen((session) {
    _activeRide = session;
    _hasActiveRide = session != null && session.isActive;
    
    if (_hasActiveRide && _activeRide != session) {
      _isReturnBannerDismissed = false;
    }
    notifyListeners();
  });
}
```

The `startRide()` method creates a new session through the repository and immediately updates local state. It returns the created session to the caller so they can access the session ID for navigation. The method also ensures the return banner will be shown for this new ride.

The `endActiveRide()` method includes guard logic to prevent errors. It checks if an active ride exists before attempting to end it, returning false if there's nothing to end. This pattern prevents null pointer exceptions and makes the method safe to call from anywhere.

---

## Layer 3: ViewModel Layer (Coordination)

### File: StationMapViewModel (Refactored)

**Path:** `lib/ui/screens/station_map/view_model/station_map_view_model.dart`

The refactored StationMapViewModel now follows a clean separation pattern. Instead of holding state and business logic internally, it delegates to global states for data and services for logic. This makes the ViewModel a thin coordination layer that connects the UI to the underlying architecture.

```dart
class StationMapViewModel extends ChangeNotifier {
  final RideState _rideState;
  final StationState _stationState;
  final StationService _stationService;
  final RideService _rideService;

  StationMapViewModel({
    required RideState rideState,
    required StationState stationState,
    required StationService stationService,
    required RideService rideService,
  })  : _rideState = rideState,
        _stationState = stationState,
        _stationService = stationService,
        _rideService = rideService {
    _rideState.addListener(_onStateChanged);
    _stationState.addListener(_onStateChanged);
  }
```

The ViewModel implements the observer pattern by listening to both global states. Whenever either state changes, it calls `_onStateChanged()` which simply forwards the notification to its own listeners. This creates a chain reaction where state updates automatically propagate to the UI.

The ViewModel exposes data through simple getter properties that pass through values from the global states. These getters require no logic or transformation - they just provide convenient access for the UI. Properties like `isLoading`, `stations`, and `hasActiveRide` all delegate directly to their respective states.

Computed properties use services to derive values. For example, `showReturnModeBanner` calls the RideService with data from RideState to determine visibility. The `suggestedAlternativeDockStation` property uses StationService to find the nearest station with free docks. This keeps complex logic out of the ViewModel.

```dart
bool get showReturnModeBanner {
  return _rideService.shouldShowReturnBanner(
    hasActiveRide: _rideState.hasActiveRide,
    isBannerDismissed: _rideState.isReturnBannerDismissed,
  );
}
```

Most action methods are simple delegations to state methods. When the UI needs to load stations or select a station, the ViewModel just forwards the call to StationState. This simplicity makes the ViewModel easy to understand and test.

The `returnBikeToStation()` method demonstrates coordination between multiple layers. It first validates using RideService, then updates StationState if validation passes, and finally updates RideState to end the ride. This orchestration is the primary responsibility of ViewModels in this architecture.

---

## Layer 4: View Layer (New Screens)

### File: BikeConnectingScreen

**Path:** `lib/ui/screens/bike_connecting/bike_connecting_screen.dart`

BikeConnectingScreen displays an animated progress indicator while the app unlocks a bike and creates a ride session. After the user scans a QR code, they're navigated to this screen which shows a professional connecting experience. The screen runs operations in parallel and enforces a minimum 2-second delay to ensure users see the smooth animation.

```dart
class BikeConnectingScreen extends StatefulWidget {
  final String bikeCode;
  final String stationName;

  const BikeConnectingScreen({
    super.key,
    required this.bikeCode,
    required this.stationName,
  });
```

The screen uses an AnimationController to drive a 1.8-second progress animation with smooth easing curves. A `_currentStep` variable tracks which phase to highlight in the UI: QR scanned, Verifying, or Unlocking. When the animation reaches 50% completion, it automatically advances to step 2.

The `_connect()` method uses `Future.wait` to run bike unlock and ride session creation in parallel. This is much faster than sequential awaits. A minimum 2-second delay ensures users see the animation even if network operations complete instantly, preventing a glitchy experience.

The progress bar uses AnimatedBuilder which only rebuilds the progress indicator widget, not the entire screen. This is more efficient than calling setState() for every animation frame and provides smooth 60fps animation without performance issues.

---

### File: StationsScreen (Detailed Station View)

**Path:** `lib/ui/screens/station_detail/stations_screen.dart`

StationsScreen provides a detailed view of a station with an interactive map and bike slot availability. It uses OpenStreetMap which requires no API key and is free for unlimited use. The screen features a draggable bottom sheet that users can slide up and down to see station details.

```dart
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
    MarkerLayer(markers: [/* station markers */]),
  ],
)
```

The draggable bottom sheet follows the user's finger during drag gestures. The sheet height is clamped between minimum and maximum values to prevent it from going too high or too low. When the user releases their finger, the sheet snaps to the nearest position with a smooth animation.

Bike slots are generated using deterministic randomness based on the station ID hash. This means the same station always shows bikes in the same positions, but different stations have different patterns. This provides visual variety without needing backend data for each individual slot.

The station switcher uses modulo arithmetic to cycle through stations. The expression `(index + 1) % length` wraps back to 0 after reaching the last item, allowing infinite cycling through the station list without bounds checking.

---

## Layer 5: Dependency Injection

### File: main_dev.dart

**Path:** `lib/main_dev.dart`

The dependency injection setup follows a layered approach. Repositories are provided first since they're the lowest level and access external data sources like GPS and mock APIs. Services are provided next since they contain pure business logic and are stateless. Global States are provided later in main_common.dart since they need to read from repositories using context.

```dart
List<SingleChildWidget> get devProviders {
  return <SingleChildWidget>[
    // Layer 1: Repositories
    Provider<StationRepository>(create: (_) => MockStationRepository()),
    Provider<BikeRepository>(create: (_) => MockBikeRepository()),
    Provider<RideRepository>(create: (_) => MockRideRepository()),
    
    // Layer 2: Services
    Provider<StationService>(create: (_) => StationService()),
    Provider<RideService>(create: (_) => RideService()),
  ];
}
```

### File: main_common.dart

**Path:** `lib/main_common.dart`

The app uses a two-stage provider setup. The first stage in main_dev.dart provides repositories and services that don't need context. The second stage in main_common.dart provides global states that need to call `context.read()` to access repositories. This two-stage approach ensures proper dependency order.

```dart
class VeloToulouseAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RideState>(
          create: (context) => RideState(context.read<RideRepository>()),
        ),
        ChangeNotifierProvider<StationState>(
          create: (context) => StationState(
            repository: context.read<StationRepository>(),
            userLocationRepository: context.read<UserLocationRepository>(),
          )..loadStations(),
        ),
      ],
      child: const VeloToulouseApp(),
    );
  }
}
```

The cascade operator (..) allows calling methods on an object immediately after creation. The StationState is created and `loadStations()` is called on it before returning, all in one expression. This loads station data as soon as the app starts.

---

## 📊 Data Flow Example: Returning a Bike

When a user returns a bike, the action flows through all architectural layers. First, the View layer captures the user's tap and calls the ViewModel. The ViewModel coordinates between the RideService for validation and the global states for updates. If validation passes, the StationState updates the bike availability and the RideState ends the active ride. Finally, all watching widgets rebuild automatically through ChangeNotifier.

```dart
// Step 1: User taps return button in View
void _onReturnBikePressed(Station station) {
  final result = viewModel.returnBikeToStation(station);
  final message = switch (result) {
    ReturnBikeResult.success => 'Bike returned successfully.',
    ReturnBikeResult.noActiveRide => 'No active ride to return.',
    ReturnBikeResult.stationFull => 'Station is full.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// Step 2: ViewModel coordinates validation and updates
ReturnBikeResult returnBikeToStation(Station station) {
  final result = _rideService.validateReturn(
    hasActiveRide: _rideState.hasActiveRide,
    station: station,
  );
  if (result != ReturnBikeResult.success) return result;
  
  _stationState.updateStationAfterReturn(station.id);
  _rideState.endActiveRide();
  return ReturnBikeResult.success;
}

// Step 3: States update and notify
// StationState increments availableBikes and calls notifyListeners()
// RideState sets hasActiveRide to false and calls notifyListeners()
// ViewModel receives notifications and calls its own notifyListeners()
// View rebuilds with updated data
```

The flow demonstrates separation of concerns: Views handle UI interactions, ViewModels coordinate operations, Services validate business rules, and States manage data. Each layer has a single responsibility and communicates through well-defined interfaces.

---

## 🧪 Testing Strategy

The layered architecture makes testing straightforward since each layer can be tested independently. Services are the easiest to test because they're pure functions with no dependencies. Global States require mocking repositories but are still straightforward. ViewModels need mocks for both states and services. Widget tests are the most complex but verify the complete user experience.

```dart
// Service Testing - Pure functions, no mocks needed
test('searchStations filters by name', () {
  final service = StationService();
  final stations = [Station(name: 'Capitole', ...), Station(name: 'Wilson', ...)];
  final results = service.searchStations(stations, 'cap', isReturnMode: false);
  expect(results.length, 1);
  expect(results[0].name, 'Capitole');
});

// State Testing - Mock repositories, test transitions
test('StationState loads stations', () async {
  final mockRepo = MockStationRepository();
  final state = StationState(repository: mockRepo, userLocationRepository: MockLocationRepository());
  expect(state.isLoading, false);
  final loadFuture = state.loadStations();
  expect(state.isLoading, true);
  await loadFuture;
  expect(state.stations.length, greaterThan(0));
});

// ViewModel Testing - Mock dependencies, verify coordination
test('ViewModel delegates to services', () {
  final viewModel = StationMapViewModel(
    rideState: MockRideState(),
    stationState: MockStationState(),
    stationService: MockStationService(),
    rideService: MockRideService(),
  );
  viewModel.searchStations('test');
  verify(mockService.searchStations(any, 'test', isReturnMode: false));
});

// Widget Testing - Test complete UI flows
testWidgets('BikeConnectingScreen shows progress', (tester) async {
  await tester.pumpWidget(MaterialApp(home: BikeConnectingScreen(bikeCode: 'TEST-01', stationName: 'Test')));
  expect(find.text('QR Code Detected!'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

---

## 🎯 Key Takeaways

The architecture achieves separation of concerns by dividing responsibilities across five layers. Services contain business logic and are stateless, making them easy to test and reuse. States manage data and are stateful, providing a single source of truth. ViewModels coordinate between layers without holding data or logic themselves. Views are purely presentational and simply observe ViewModels.

Each class follows the single responsibility principle with one clear job. StationService handles only station-related logic like searching and distance calculations. StationState manages only station data and map state. The ViewModel's sole purpose is coordination between these components.

The architecture applies dependency inversion where high-level modules don't depend on low-level implementations. ViewModels depend on State and Service interfaces, not concrete implementations. This makes it easy to swap mock implementations for real ones without changing ViewModel code. All dependencies are injected through constructors, enabling flexible testing.

Testability is built into every layer. Services use pure functions that are trivial to unit test. States can be tested with mocked repositories. ViewModels can be tested with mocked states and services. Widget tests verify complete user flows. Each layer can be tested in isolation without spinning up the entire app.

Services are reused across multiple ViewModels, eliminating code duplication. States are shared across multiple screens, preventing redundant data loading. Business logic lives in services rather than being scattered across UI code. This creates a single source of truth for each concern.

The architecture scales easily when adding new features. Create a new service for business logic, update existing states or create new ones, add a ViewModel to coordinate, and build the UI. Each layer remains independent, so changes in one layer don't ripple through the entire codebase.

---

## 🚀 Best Practices Applied

The codebase uses immutability throughout. Objects are never modified directly. Instead, new objects are created with updated values using `copyWith()`. Lists are transformed using `map()` and `toList()` rather than being mutated in place. This prevents bugs caused by shared mutable state.

Null safety is handled explicitly everywhere. Optional values use the `?` type and are checked before use. The null assertion operator `!` is only used when the compiler can't infer non-null but the logic guarantees it. Guard clauses return early when values are null rather than crashing later.

Error handling uses result types instead of exceptions for business logic. The `ReturnBikeResult` enum makes all outcomes explicit and forces callers to handle each case. Exceptions are reserved for truly exceptional situations like network failures, not expected business logic branches.

Resource cleanup happens consistently in `dispose()` methods. Animation controllers are disposed, listeners are removed from states, and subscriptions are cancelled. This prevents memory leaks where objects can't be garbage collected due to lingering references.

Context safety is maintained across async operations. Context is captured before async calls and used after they complete, preventing crashes when the widget is disposed during the async operation. The `mounted` property is checked before using context after async gaps.

---

## 🎓 Conclusion

Your VeloToulouse app demonstrates professional Flutter architecture suitable for production applications. The clean layered architecture provides clear separation of concerns, making the codebase easy to understand and maintain. SOLID principles are applied throughout, with single responsibility and dependency inversion at every layer.

The architecture is highly testable with each layer independently verifiable. Services contain pure functions that need no mocking. States encapsulate data management with mocked repositories. ViewModels coordinate through injected dependencies. This design makes it practical to maintain high test coverage.

The codebase is built for scalability. Adding new features requires creating services for logic, updating states for data, adding ViewModels for coordination, and building views for UI. Existing code remains untouched, preventing regression bugs. Each layer can evolve independently.

The architecture emphasizes maintainability through centralized business logic. Services contain reusable logic accessed by multiple ViewModels. States provide a single source of truth for data. Changes to business rules require updating only the relevant service, not scattered UI code.

This demonstrates understanding of advanced Flutter development concepts including reactive state management, dependency injection, layered architecture, and professional design patterns. The codebase is ready for enhancements like real API integration, offline caching, user authentication, payment systems, ride history, and analytics.

**Next Steps:** Add comprehensive unit tests for services, integrate real API endpoints, implement offline caching with local database, add user authentication and profiles, integrate payment processing, create ride history views, and add analytics tracking. The solid foundation makes these enhancements straightforward to implement.
